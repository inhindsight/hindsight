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
end
