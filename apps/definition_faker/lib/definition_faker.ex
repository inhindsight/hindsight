defmodule DefinitionFaker do
  @spec dataset(override :: map) :: {:ok, Dataset.t()}
  def dataset(override) do
    DefinitionFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  @spec owner(override :: map) :: {:ok, Dataset.Owner.t()}
  def owner(override) do
    DefinitionFaker.Owner.default()
    |> Map.merge(override)
    |> Dataset.Owner.new()
  end

  @spec data(override :: map) :: {:ok, Data.t()}
  def data(override) do
    DefinitionFaker.Data.default()
    |> Map.merge(override)
    |> Data.new()
  end

  @spec extract(override :: map) :: {:ok, Extract.t()}
  def extract(override) do
    DefinitionFaker.Extract.default()
    |> Map.merge(override)
    |> Extract.new()
  end

  @spec schedule(override :: map) :: {:ok, Schedule.t()}
  def schedule(override) do
    DefinitionFaker.Schedule.default()
    |> Map.merge(override)
    |> Schedule.new()
  end

  @spec transform(override :: map) :: {:ok, Transform.t()}
  def transform(override) do
    DefinitionFaker.Transform.default()
    |> Map.merge(override)
    |> Transform.new()
  end
end
