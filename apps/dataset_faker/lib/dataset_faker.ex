defmodule DatasetFaker do
  @spec dataset(map()) :: Dataset.t()
  def dataset(override) do
    DatasetFaker.Dataset.default()
    |> Map.merge(override)
    |> Dataset.new()
  end

  @spec attachment(map()) :: Dataset.Attachment.t()
  def attachment(override) do
    DatasetFaker.Attachment.default()
    |> Map.merge(override)
    |> Dataset.Attachment.new()
  end
end
