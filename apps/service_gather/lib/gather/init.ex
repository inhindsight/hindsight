defmodule Gather.Init do
  use GenServer
  use Retry

  alias Gather.Extraction

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    supervisor_ref = setup_monitor()
    start_extractions()
    {:ok, %{supervisor_ref: supervisor_ref}}
  end

  @dialyzer {:nowarn_function, handle_info: 2}
  def handle_info({:DOWN, supervisor_ref, _, _, _}, %{supervisor_ref: supervisor_ref} = state) do
    retry with: constant_backoff(100) |> Stream.take(10), atoms: [false] do
      Process.whereis(Extraction.Supervisor) != nil
    after
      _ ->
        supervisor_ref = setup_monitor()
        start_extractions()
        {:noreply, Map.put(state, :supervisor_ref, supervisor_ref)}
    else
      _ -> {:stop, "Supervisor not available", state}
    end
  end

  defp setup_monitor() do
    Process.whereis(Extraction.Supervisor)
    |> Process.monitor()
  end

  defp start_extractions() do
    Extraction.Store.get_all!()
    |> Enum.each(fn extract ->
      Extraction.Supervisor.start_child({Extraction, extract: extract})
    end)
  end
end
