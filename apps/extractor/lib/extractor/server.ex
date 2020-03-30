defmodule Extractor.Server do
  use GenServer, shutdown: 10_000

  def start_link(extractor, source_context) do
    GenServer.start_link(__MODULE__, {extractor, source_context})
  end

  def stop(_extractor, server) do
    GenServer.call(server, :stop, 10_000)
  end

  def delete(_extractor) do
    :ok
  end

  @impl GenServer
  def init({extractor, source_context}) do
    state = %{
      extractor: extractor,
      source_context: source_context
    }

    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl GenServer
  def handle_continue(:init, state) do
    with {:ok, extract_context} <- Ok.reduce(state.extractor.steps, Extract.Context.new(), &Extract.Step.execute/2),
         :ok <- run_stream(state, extract_context) do
      {:stop, :normal, state}
    else
      {:error, reason} ->
        {:stop, reason, state}
    end
  end

  defp run_stream(state, extract_context) do
    Extract.Context.get_stream(extract_context)
    |> Enum.each(fn chunk ->
      chunk
      |> Enum.map(&Map.get(&1, :data))
      |> Enum.map(fn msg -> %Source.Message{original: msg, value: msg} end)
      |> Source.Handler.inject_messages(state.source_context)

      Extract.Context.run_after_functions(extract_context, chunk)
    end)
  catch
    _, reason ->
      Extract.Context.run_error_functions(extract_context)
      {:error, reason}
  end
end
