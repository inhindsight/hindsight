defmodule Broadcast.Transformations do
  @instance Broadcast.Application.instance()
  @collection "transformations"

  def persist(%Transform{dataset_id: dataset_id} = transform) do
    Brook.ViewState.merge(@collection, dataset_id, %{"transform" => transform})
  end

  def get(dataset_id) do
    with {:ok, %{"transform" => transform}} <-
           Brook.ViewState.get(@instance, @collection, dataset_id) do
      Ok.ok(transform)
    end
  end
end
