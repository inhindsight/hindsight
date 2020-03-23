defmodule Kafka.Topic do
  use Definition, schema: Kafka.Topic.V1

  defstruct version: 1,
            pid: nil,
            endpoints: nil,
            topic: nil,
            partitions: 1,
            partitioner: "default",
            key_path: []

  defimpl Destination do

    defdelegate start_link(t, dictionary), to: Kafka.Topic.Impl

    def write(t,dictionary, messages) do
    end

    def delete(t) do
    end
  end
end

defmodule Kafka.Topic.V1 do
  use Definition.Schema

  def s do
    schema(%Kafka.Topic{
      version: version(1),
      pid: spec(is_pid()),
      endpoints: spec(is_list()),
      topic: required_string(),
      partitions: spec(pos_integer?()),
      partitioner: spec(fn x -> x in ["default", "random", "md5"] end),
      key_path: access_path()
    })
  end
end
