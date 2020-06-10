defmodule Channel.Topic do
  @moduledoc """
  Defines a channel topic, encapsulating destination information for
  a WebSocket. Data can be cached so a user receives the cached data
  on subscription to the channel.

  ## Configuration

  * `name` - Required. Topic name. Do NOT prepend with app-specific
  routing information. (ex. `broadcast:topic_name`).
  * `cache` - Number of messages to cache and push to user on channel
  join. Defaults to 0 (off).
  """
  use Definition, schema: Channel.Topic.V1
  use JsonSerde, alias: "channel_topic"

  @type t :: %__MODULE__{
          name: String.t(),
          cache: non_neg_integer
        }

  defstruct name: nil,
            cache: 0

  defimpl Destination do
    def start_link(_topic, _context) do
      raise "Not Implemented"
    end

    def write(_topic, _server, _messages) do
      raise "Not Implemented"
    end

    def stop(_topic, _server) do
      :ok
    end

    def delete(_topic) do
      :ok
    end
  end
end

defmodule Channel.Topic.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Channel.Topic{
      name: required_string(),
      cache: spec(is_integer())
    })
  end
end
