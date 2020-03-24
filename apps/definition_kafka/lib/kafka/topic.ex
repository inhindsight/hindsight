defmodule Kafka.Topic do
  use Definition, schema: Kafka.Topic.V1

  defstruct version: 1,
            pid: nil,
            endpoints: nil,
            topic: nil,
            partitions: 1,
            partitioner: "default",
            key_path: []

  def on_new(struct) do
    endpoints =
      struct.endpoints
      |> List.wrap()
      |> Enum.map(&fix_endpoint/1)

    %{struct | endpoints: endpoints}
    |> Ok.ok()
  end

  def fix_endpoint([host, port]) when is_binary(host) and is_integer(port) do
    {String.to_atom(host), port}
  end
  def fix_endpoint(endpoint), do: endpoint


  defimpl Source do
    defdelegate start_link(t, init_opts), to: Kafka.Topic.Source
    defdelegate stop(t), to: Kafka.Topic.Source
    defdelegate delete(t), to: Kafka.Topic.Source
  end

  defimpl Destination do
    defdelegate start_link(t, dictionary), to: Kafka.Topic.Destination
    defdelegate write(t, dictionary, messages), to: Kafka.Topic.Destination
    defdelegate stop(t), to: Kafka.Topic.Destination
    defdelegate delete(t), to: Kafka.Topic.Destination
  end
end

defmodule Kafka.Topic.V1 do
  use Definition.Schema

  def s do
    schema(%Kafka.Topic{
      version: version(1),
      pid: spec(is_pid() or is_nil()),
      endpoints: spec(is_list()),
      topic: required_string(),
      partitions: spec(pos_integer?()),
      partitioner: spec(fn x -> x in ["default", "random", "md5"] end),
      key_path: access_path()
    })
  end
end
