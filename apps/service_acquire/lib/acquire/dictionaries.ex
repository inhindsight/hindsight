defmodule Acquire.Dictionaries do
  @instance Acquire.Application.instance()
  @collection "fields"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Transform.t() | Load.Persist.t()) :: :ok
  def persist(%Transform{} = transform) do
    with {:ok, dictionary} <-
           Transformer.transform_dictionary(transform.steps, transform.dictionary) do
      fields = %{"wkt" => wkt(dictionary), "dictionary" => dictionary}
      Brook.ViewState.merge(@collection, identifier(transform), fields)
    end
  end

  def persist(%Load.Persist{destination: destination} = persist) do
    Brook.ViewState.merge(@collection, identifier(persist), %{"destination" => destination})
  end

  @spec get(dataset_id :: String.t(), subset_id :: String.t(), field_type :: String.t()) ::
          {:ok, String.t() | [String.t()] | Dictionary.t()} | {:error, term}
  def get(dataset_id, subset_id, field_type) do
    with {:ok, map} when not is_nil(map) <-
           Brook.get(@instance, @collection, identifier(dataset_id, subset_id)),
         true <- Map.has_key?(map, field_type) do
      Ok.ok(Map.get(map, field_type))
    else
      false -> Ok.error("#{field_type} not found for #{dataset_id} #{subset_id}")
      {:ok, nil} -> Ok.error("#{field_type} not found for #{dataset_id} #{subset_id}")
      error_result -> error_result
    end
  end

  @spec get_destination(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, String.t()} | {:error, term}
  def get_destination(dataset_id, subset_id) do
    get(dataset_id, subset_id, "destination")
  end

  defp wkt(dictionary) do
    Dictionary.get_by_type(dictionary, Dictionary.Type.Wkt.Point)
    |> Enum.map(&Enum.join(&1, "."))
  end
end
