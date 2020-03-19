defmodule Broadcast.Transformations do
  @instance Broadcast.Application.instance()
  @collection "transformations"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Transform.t()) :: :ok
  def persist(%Transform{} = transform) do
    Brook.ViewState.merge(@collection, identifier(transform), %{"transform" => transform})
  end

  @spec get(String.t(), String.t()) :: {:ok, Transform.t()} | {:ok, nil} | {:error, term}
  def get(dataset_id, subset_id) do
    with {:ok, %{"transform" => transform}} <-
           Brook.ViewState.get(@instance, @collection, identifier(dataset_id, subset_id)) do
      Ok.ok(transform)
    end
  end

  @spec delete(Delete.t()) :: :ok
  def delete(%Delete{} = delete) do
    Brook.ViewState.delete(@collection, identifier(delete))
  end
end
