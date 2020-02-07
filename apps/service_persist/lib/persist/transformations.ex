defmodule Persist.Transformations do
  @instance Persist.Application.instance()
  @collection "transformations"

  import Definition, only: [identifier: 1, identifier: 2]

  @spec persist(Transform.t()) :: :ok
  def persist(transform) do
    Brook.ViewState.merge(@collection, identifier(transform), %{"transform" => transform})
  end

  @spec get(dataset_id :: String.t(), subset_id :: String.t()) ::
          {:ok, Transform.t()} | {:ok, nil} | {:error, term}
  def get(dataset_id, subset_id) do
    key = identifier(dataset_id, subset_id)

    with {:ok, %{"transform" => transform}} <- Brook.get(@instance, @collection, key) do
      Ok.ok(transform)
    end
  end
end
