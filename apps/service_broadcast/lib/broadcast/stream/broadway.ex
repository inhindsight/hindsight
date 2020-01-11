defmodule Broadcast.Stream.Broadway do
  use Broadway

  @config Application.get_env(:service_broadcast, __MODULE__, [])
  @broadway_config Keyword.fetch!(@config, :broadway_config)

  def start_link(args) do
    %Broadcast.Load{id: id} = Keyword.fetch!(args, :load)

    config = Keyword.put(@broadway_config, :name, :"#{__MODULE__}-#{id}")
    Broadway.start_link(__MODULE__, config)
  end

  def handle_message(_processor, %Broadway.Message{data: data} = message, _context) do
    case Jason.decode(data.value) do
      {:ok, decoded_value} ->
        BroadcastWeb.Endpoint.broadcast!("broadcast:#{data.topic}", "update", decoded_value)
        message
      {:error, reason} ->
        Broadway.Message.failed(message, reason)
    end
  end

end
