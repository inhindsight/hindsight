defmodule Definition.Dataset do
  @type t() :: %__MODULE__{}
  @schema Definition.Schema.Dataset.V1

  defstruct version: nil,
            id: nil,
            owner_id: nil,
            title: nil,
            description: "",
            keywords: [],
            license: nil,
            created_ts: nil,
            profile: %{
              updated_ts: "",
              profiled_ts: "",
              modified_ts: "",
              spatial: [],
              temporal: []
            }

  @spec new(map()) :: t()
  def new(%{} = input) do
    map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

    struct(__MODULE__, map)
    |> Norm.conform(@schema.s())
  end
end
