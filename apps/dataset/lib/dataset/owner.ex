defmodule Dataset.Owner do
  @type t() :: %__MODULE__{}
  @schema Dataset.Schema.Owner.V1

  defstruct version: nil,
            id: nil,
            name: nil,
            title: nil,
            description: "",
            url: "",
            image: "",
            contact: %{
              name: nil,
              email: nil
            }

  @spec new(map()) :: t()
  def new(%{} = input) do
    map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

    struct(__MODULE__, map)
    |> Norm.conform(@schema.s())
  end
end
