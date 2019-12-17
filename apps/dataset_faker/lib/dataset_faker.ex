defmodule DatasetFaker do
  @spec dataset(map()) :: Dataset.t()
  def dataset(override) do
    DatasetFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  @spec owner(map()) :: Dataset.Owner.t()
  def owner(override) do
    DatasetFaker.Owner.default()
    |> Map.merge(override)
    |> Dataset.Owner.new()
  end
end
