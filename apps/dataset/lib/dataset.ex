defmodule Dataset do
  @moduledoc "TODO"
  @version 1

  import Norm

  defstruct version: @version,
            id: nil,
            org_id: nil,
            created_ts: nil,
            modified_ts: nil,
            title: nil,
            description: "",
            keywords: [],
            license: nil,
            contact: %{name: nil, email: nil},
            boundaries: %{spatial: [], temporal: []},
            data: []

  @type t() :: %__MODULE__{}

  @spec new(map()) :: t()
  def new(%{} = input) do
    map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

    struct(__MODULE__, map)
    |> conform(s())
  end

  @spec s() :: %Norm.Schema{}
  def s do
    schema(%__MODULE__{
      version: spec(fn v -> v == @version end),
      id: Dataset.Schema.string(),
      org_id: Dataset.Schema.string(),
      title: Dataset.Schema.string(),
      description: spec(is_binary()),
      keywords: spec(is_list()),
      license: Dataset.Schema.string(),
      created_ts: Dataset.Schema.timestamp(),
      modified_ts: Dataset.Schema.timestamp(),
      contact: Dataset.Schema.contact(),
      boundaries: Dataset.Schema.boundaries(),
      data: spec(is_list())
    })
  end
end
