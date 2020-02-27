defmodule Persist.Writer.DirectUpload do
  @behaviour Writer
  use GenServer

  @type init_opts :: [
          load: Load.Persist.t(),
          dictionary: Dictionary.t()
        ]

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
      dictionary: dictionary
    }

    case Persist.TableCreator.create(load.destination, dictionary) do
      :ok -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    with {:ok, data_file} <- Persist.DataFile.open(state.load.destination, state.dictionary),
         {:ok, _size} <- Persist.DataFile.write(data_file, messages),
         {:ok, _} <- upload_file(data_file, state.load.destination) do
      {:reply, :ok, state}
    else
      {:error, reason} -> {:stop, reason, {:error, reason}, state}
    end
  end

  defp upload_file(data_file, destination) do
    file_path = Persist.DataFile.close(data_file)
    extension = Path.extname(file_path)
    result = Persist.Uploader.upload(file_path, "#{destination}/#{:erlang.system_time(:nanosecond)}#{extension}")
    File.rm(file_path)
    result
  end
end
