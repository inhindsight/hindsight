defmodule Acquire.Dictionaries do
  @instance Acquire.Application.instance()
  @collection "fields"

  @spec persist(Transform.t()) :: :ok
  def persist(%Transform{dataset_id: id} = transform) do
    with {:ok, dictionary} <-
           Transformer.transform_dictionary(transform.steps, transform.dictionary) do
      fields = %{"wkt" => wkt(dictionary), "dictionary" => dictionary}
      Brook.ViewState.merge(@collection, id, fields)
    end
  end

  @spec get(String.t(), String.t()) :: {:ok, [String.t()]} | {:error, term}
  def get(dataset_id, field_type) do
    Brook.get(@instance, @collection, dataset_id)
    |> Ok.map(&Map.get(&1, field_type, []))
  end

  defp wkt(dictionary) do
    Dictionary.get_by_type(dictionary, Transformer.Wkt.Point)
    |> Enum.map(&Enum.join(&1, "."))
  end
end
