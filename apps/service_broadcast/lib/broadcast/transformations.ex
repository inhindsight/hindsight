defmodule Broadcast.Transformations do
  @instance Broadcast.Application.instance()
  @collection "transformations"

  @spec persist(Transform.t()) :: :ok
  def persist(%Transform{dataset_id: dataset_id} = transform) do
    Brook.ViewState.merge(@collection, dataset_id, %{"transform" => transform})
  end

  @spec get(String.t()) :: {:ok, Transform.t()} | {:ok, nil} | {:error, term}
  def get(dataset_id) do
    with {:ok, %{"transform" => transform}} <-
           Brook.ViewState.get(@instance, @collection, dataset_id) do
      Ok.ok(transform)
    end
  end

  @spec delete(Delete.t()) :: :ok
  def delete(%Delete{} = delete) do
    Brook.ViewState.delete(@collection, delete.dataset_id)
  end

end
