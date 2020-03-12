defmodule Define.DataDefinition do
  use Ecto.Schema
  use Definition, schema: DataDefinition.V1
  import Ecto.Changeset

  schema "data_definition" do
    field(:version, :integer, default: 1)
    field(:dataset_id, :string)
    field(:subset_id, :string, default: "default")
    # {:map, inner_type}
    field(:dictionary, :map)
    field(:extract_destination, :string)
    field(:extract_steps, {:array, :string})
    field(:transform_steps, {:array, :string})
    field(:persist_source, :string)
    field(:persist_destination, :string)
  end

  @fields [
    :dataset_id,
    :subset_id,
    :dictionary,
    :extract_destination,
    :extract_steps,
    :transform_steps,
    :persist_source,
    :persist_destination
  ]

  def changeset(user, attrs) do
    user
    |> cast(attrs, @fields)
  end

  def create(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def update(user, attrs \\ %{}) do
    changeset(user, attrs)
  end

  @impl Definition
  def on_new(%{dictionary: list} = data) when is_list(list) do
    Map.put(data, :dictionary, Dictionary.from_list(list))
    |> Ok.ok()
  end

  def on_new(data), do: Ok.ok(data)
end

defmodule DataDefinition.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Define.DataDefinition{
      version: version(1),
      dataset_id: required_string(),
      subset_id: required_string(),
      dictionary: of_struct(Dictionary.Impl),
      extract_destination: required_string(),
      extract_steps: required_string(),
      transform_steps: required_string(),
      persist_source: required_string(),
      persist_destination: required_string()
    })
  end
end
