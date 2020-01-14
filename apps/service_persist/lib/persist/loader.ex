defmodule Persist.Loader do
  use GenServer
  use Annotated.Retry

  @config Application.get_env(:service_persist, __MODULE__, [])
  @writer Keyword.get(@config, :writer, Persist.Writer)
  @broadway Keyword.get(@config, :broadway, Persist.Load.Broadway)
  @max_retries Keyword.get(@config, :max_retries, 10)

  @type init_opts :: [
    load: %Load.Persist{}
  ]

  @spec start_link(init_opts) :: GenServer.on_start()
  def start_link(init_arg) do
    name = Keyword.get(init_arg, :name, nil)
    GenServer.start_link(__MODULE__, init_arg, name: name)
  end

  @impl GenServer
  def init(init_arg) do
    Process.flag(:trap_exit, true)
    load = Keyword.fetch!(init_arg, :load)

    with {:ok, writer_pid} <- start_writer(load),
         writer_function <- fn msgs -> @writer.write(writer_pid, msgs) end,
         {:ok, broadway_pid} <- start_broadway(load, writer_function) do
      {:ok, %{writer_pid: writer_pid, broadway_pid: broadway_pid}}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_writer(load) do
    @writer.start_link(load: load)
  end

  @retry with: exponential_backoff(100) |> take(@max_retries)
  defp start_broadway(load, writer) do
    @broadway.start_link(load: load, writer: writer)
  end
end
