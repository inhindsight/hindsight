defmodule Presto.Table.Destination do
  use GenServer
  use Properties, otp_app: :definition_presto
  require Logger

  alias Presto.Table.{DataFile, DataStorage, Manager}

  getter(:catalog, required: true)
  getter(:user, required: true)
  getter(:write_timeout, default: 25_000)
  getter(:no_activity_timeout, default: 10_000)
  getter(:staged_batches_count, default: 50)

  def start_link(table, context) do
    GenServer.start_link(__MODULE__, {table, context})
    |> Ok.map(&%{table | pid: &1})
  end

  def write(table, messages) do
    GenServer.call(table.pid, {:write, messages}, write_timeout())
  end

  def stop(table) do
    GenServer.call(table.pid, :stop, write_timeout())
  end

  def delete(table) do
    session = new_session(table)
    Manager.delete(session, table.name)

    staging_table = "#{table.name}__staging"
    Manager.delete(session, staging_table)
    :ok
  end

  def init({table, context}) do
    state = %{
      table: table,
      context: context,
      session: new_session(table),
      staging_table: "#{table.name}__staging",
      staged: 0
    }

    {:ok, state, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    with :ok <- Manager.create(state.session, state.table.name, state.context.dictionary, :orc),
         {:ok, _} <-
           Manager.create_from(state.session, state.staging_table, state.table.name, format: DataFile.format()) do
      {:noreply, state}
    else
      {:error, reason} ->
        Logger.error(fn -> "#{__MODULE__}: handle_continue failed - #{inspect(reason)}" end)
        {:stop, reason, state}
    end
  catch
    _, reason ->
      Logger.error(fn -> "#{__MODULE__}: unexpected error - #{inspect(reason)} - #{inspect(__STACKTRACE__)}" end)
    {:stop, reason, state}
  end

  def handle_call({:write, messages}, from, state) do
    :ok = write_data(messages, state)
    new_staged = state.staged + 1

    case new_staged >= staged_batches_count() do
      true ->
        GenServer.reply(from, :ok)
        copy_to_production(state)
        {:noreply, %{state | staged: 0}}
      false ->
        {:reply, :ok, %{state | staged: new_staged}, no_activity_timeout()}
    end
  catch
    _, reason ->
      Logger.error(fn -> "#{__MODULE__}: unexpected error - #{inspect(reason)} - #{inspect(__STACKTRACE__)}" end)
    {:stop, reason, state}
  end

  def handle_call(:stop, _from, state) do
    Logger.info(fn -> "#{__MODULE__}: asked to terminate" end)
    {:stop, :normal, :ok, state}
  end

  def handle_info(:timeout, %{staged: staged} = state) when staged > 0 do
    copy_to_production(state)
    {:noreply, %{state | staged: 0}}
  end

  def handle_info(:timeout, state) do
    {:noreply, state}
  end

  defp write_data(messages, state) do
    with {:ok, data_file} <- Presto.Table.DataFile.open(state.staging_table, state.context.dictionary),
         {:ok, _size} <- Presto.Table.DataFile.write(data_file, messages),
         file_path <- Presto.Table.DataFile.close(data_file),
         {:ok, _} <- upload_file(file_path, state.staging_table) do
      File.rm(file_path)
      :ok
    end
  end

  defp upload_file(file_path, table_name) do
    extension = Path.extname(file_path)

    DataStorage.upload(
      file_path,
      "#{table_name}/#{:erlang.system_time(:nanosecond)}#{extension}"
    )
  end

  defp copy_to_production(state) do
    Logger.debug(fn ->
      "#{__MODULE__}: Copying from #{state.staging_table} to #{state.table.name}"
    end)

    {:ok, _} = Presto.Table.Manager.copy(state.session, state.staging_table, state.table.name)
    :ok = DataStorage.delete(state.staging_table)

    Logger.debug(fn ->
      "#{__MODULE__}: DONE Copying from #{state.staging_table} to #{state.table.name}"
    end)
  end

  defp new_session(table) do
    Prestige.new_session(
      url: table.url,
      catalog: catalog(),
      schema: table.schema,
      user: user()
    )
  end
end
