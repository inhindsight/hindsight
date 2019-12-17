defmodule Definition do
  @callback new(map()) :: struct()

  defmacro __using__(opts) do
    quote do
      @behaviour Definition

      @type t() :: %__MODULE__{}
      @schema Keyword.fetch!(unquote(opts), :schema)

      @impl Definition
      @spec new(map()) :: t()
      def new(%{} = input) do
        map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

        struct(__MODULE__, map)
        |> Norm.conform(@schema.s())
      end

      defoverridable Definition
    end
  end
end
