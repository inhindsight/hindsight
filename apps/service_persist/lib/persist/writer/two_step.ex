defmodule Persist.Writer.TwoStep do
  @behaviour Writer
  use GenServer
  use Properties, otp_app: :service_persist

  getter(:writer, default: Persist.Writer.DirectUpload)
  getter(:call_timeout, default: 25_000)

  @type init_opts :: [
          load: Load.Persist.t(),
          dictionary: Dictionary.t(),
          name: GenServer.name()
        ]

  @impl Writer
  def write(server, messages, opts \\ []) do
    GenServer.call(server, {:write, messages, opts}, call_timeout())
  end

  @impl Writer
  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, server_opts)
  end

  @impl GenServer
  def init(init_opts) do
    Process.flag(:trap_exit, true)

    state = %{
      load: Keyword.fetch!(init_opts, :load),
      dictionary: Keyword.fetch!(init_opts, :dictionary)
    }

    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, state) do
    Persist.TableManager.create(state.load.destination, state.dictionary)

    staging_table = state.load.destination <> "__staging"
    updated_load = %{state.load | destination: staging_table}
    {:ok, writer_pid} = writer().start_link(load: updated_load, dictionary: state.dictionary)

    new_state =
      state
      |> Map.put(:writer_pid, writer_pid)
      |> Map.put(:staging_table, staging_table)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:write, messages, opts}, _from, state) do
    writer().write(state.writer_pid, messages, opts)
    Persist.TableManager.copy(state.staging_table, state.load.destination)
    Persist.DataStorage.delete(state.staging_table)

    {:reply, :ok, state}
  end

  @impl GenServer
  def terminate(reason, state) do
    unless Map.get(state, :writer_pid) |> is_pid() do
      Process.exit(state.writer_pid, reason)
    end

    state
  end
end
