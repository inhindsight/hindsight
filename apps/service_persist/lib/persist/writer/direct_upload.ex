defmodule Persist.Writer.DirectUpload do
  @behaviour Writer
  use GenServer
  use Properties, otp_app: :service_persist

  @type init_opts :: [
          load: Load.Persist.t(),
          dictionary: Dictionary.t(),
          name: GenServer.name()
        ]

  getter(:call_timeout, default: 20_000)

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
  def init(init_arg) do
    Process.flag(:trap_exit, true)

    load = Keyword.fetch!(init_arg, :load)
    dictionary = Keyword.fetch!(init_arg, :dictionary)

    state = %{
      load: load,
      dictionary: dictionary
    }

    case Persist.TableManager.create(load.destination, dictionary, Persist.DataFile.format()) do
      :ok -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    with {:ok, data_file} <- Persist.DataFile.open(state.load.destination, state.dictionary),
         {:ok, _size} <- Persist.DataFile.write(data_file, messages),
         file_path <- Persist.DataFile.close(data_file),
         {:ok, _} <- upload_file(file_path, state.load.destination) do
      File.rm(file_path)
      {:reply, :ok, state}
    else
      {:error, reason} -> {:stop, reason, {:error, reason}, state}
    end
  end

  defp upload_file(file_path, destination) do
    extension = Path.extname(file_path)

    Persist.DataStorage.upload(
      file_path,
      "#{destination}/#{:erlang.system_time(:nanosecond)}#{extension}"
    )
  end
end
