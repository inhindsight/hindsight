defmodule Define.DataDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_definition" do
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
end
