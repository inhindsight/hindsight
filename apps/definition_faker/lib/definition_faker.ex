defmodule DefinitionFaker do
  @spec dataset(override :: map) :: Dataset.t()
  def dataset(override) do
    DefinitionFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  @spec owner(override :: map) :: Dataset.Owner.t()
  def owner(override) do
    DefinitionFaker.Owner.default()
    |> Map.merge(override)
    |> Dataset.Owner.new()
  end
end
