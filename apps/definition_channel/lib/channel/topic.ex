defmodule Channel.Topic do
  use Definition, schema: Channel.Topic.V1

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
  use Definition.Schema

  def s do
    schema(%Channel.Topic{
      name: required_string(),
      cache: spec(is_integer())
    })
  end
end
