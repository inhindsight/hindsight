defmodule DatasetFaker do
  @spec dataset(map()) :: Dataset.t()
  def dataset(override) do
    DatasetFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end
end
