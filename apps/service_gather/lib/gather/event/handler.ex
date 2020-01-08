defmodule Gather.Event.Handler do
  use Brook.Event.Handler

  alias Gather.Extraction

  @config Application.get_env(:service_gather, __MODULE__, [])
  @writer Keyword.get(@config, :writer, Gather.Writer)

  def handle_event(%Brook.Event{type: "gather:extract:start", data: %Extract{} = extract}) do
    {:ok, pid} = @writer.start_link(extract: extract)
    {:ok, stream} = Extract.Steps.execute(extract.steps)

    messages = Enum.to_list(stream)
    @writer.write(pid, messages)
    Extraction.Store.persist(extract)
  end

  def handle_event(%Brook.Event{type: "gather:extract:stop"}) do
    :ok
  end
end
