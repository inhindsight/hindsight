defmodule DefinitionFaker do
  alias Definition.{Dataset, Owner}

  @spec dataset(override :: map) :: Dataset.t()
  def dataset(override) do
    DefinitionFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  @spec owner(override :: map) :: Owner.t()
  def owner(override) do
    DefinitionFaker.Owner.default()
    |> Map.merge(override)
    |> Owner.new()
  end
end
