defmodule Persist.Writer.DirectUpload do
  @behaviour Writer
  use GenServer
  use Properties, otp_app: :service_persist

  @type init_opts :: [
          load: Load.Persist.t(),
          dictionary: Dictionary.t()
        ]

  getter(:data_file, default: Persist.DataFile.Avro)
  getter(:uploader, default: Persist.Uploader.S3)
  getter(:table_creator, default: Persist.TableCreator.Presto)

  @impl Writer
  def write(server, messages, opts \\ []) do
    GenServer.call(server, {:write, messages, opts})
  end

  @impl Writer
  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    name = Keyword.get(init_arg, :name, nil)
    GenServer.start_link(__MODULE__, init_arg, name: name)
  end

  @impl GenServer
  def init(init_arg) do
    Process.flag(:trap_exit, true)

    load = Keyword.fetch!(init_arg, :load)
    dictionary = Keyword.fetch!(init_arg, :dictionary)

    state = %{
      load: load,
      dictionary: dictionary,
    }

    case table_creator().create(load.destination, dictionary) do
      :ok -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    with {:ok, data_file} <- data_file().open(state.load.destination, state.dictionary),
         {:ok, _size} <- data_file().write(data_file, messages),
         {:ok, _} <- upload_file(data_file, state.load.destination) do
      {:reply, :ok, state}
    else
      {:error, reason} -> {:stop, reason, {:error, reason}, state}
    end
  end

  defp upload_file(data_file, destination) do
    file_path = data_file().close(data_file)
    result = uploader().upload(file_path, "#{destination}/#{:erlang.system_time(:nanosecond)}")
    File.rm(file_path)
    result
  end
end
