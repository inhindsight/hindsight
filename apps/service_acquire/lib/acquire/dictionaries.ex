defmodule Acquire.Dictionaries do
  @instance Acquire.Application.instance()
  @collection "fields"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Transform.t() | Load.Persist.t()) :: :ok
  def persist(%Transform{} = transform) do
    with {:ok, dictionary} <-
           Transformer.transform_dictionary(transform.steps, transform.dictionary) do
      fields = %{"dictionary" => dictionary}
      Brook.ViewState.merge(@collection, identifier(transform), fields)
    end
  end

  def persist(%Load.Persist{destination: destination} = persist) do
    Brook.ViewState.merge(@collection, identifier(persist), %{"destination" => destination})
  end

  @spec delete(Delete.t()) :: :ok
  def delete(%Delete{} = delete) do
    Brook.ViewState.delete(@collection, identifier(delete))
  end

  @spec get_dictionary(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, Dictionary.t()} | {:error, term}
  def get_dictionary(dataset_id, subset_id) do
    get(dataset_id, subset_id, "dictionary")
  end

  @spec get_destination(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, String.t()} | {:error, term}
  def get_destination(dataset_id, subset_id) do
    get(dataset_id, subset_id, "destination")
  end

  defp get(dataset_id, subset_id, field_type) do
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
end
