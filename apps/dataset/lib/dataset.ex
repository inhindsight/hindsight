defmodule Dataset do
  @type t() :: %__MODULE__{}
  @schema Application.get_env(:dataset, :schema)

  defstruct version: nil,
            id: nil,
            org_id: nil,
            created_ts: nil,
            modified_ts: nil,
            title: nil,
            description: "",
            keywords: [],
            license: nil,
            contact: %{name: nil, email: nil},
            boundaries: %{spatial: [], temporal: []}

  @spec new(map()) :: t()
  def new(%{} = input) do
    map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

    struct(__MODULE__, map)
    |> Norm.conform(@schema.s())
  end
end
