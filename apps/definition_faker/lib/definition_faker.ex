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

  @spec data(override :: map) :: Data.t()
  def data(override) do
    DefinitionFaker.Data.default()
    |> Map.merge(override)
    |> Data.new()
  end

  @spec extract(override :: map) :: Extract.t()
  def extract(override) do
    DefinitionFaker.Extract.default()
    |> Map.merge(override)
    |> Extract.new()
  end
end
