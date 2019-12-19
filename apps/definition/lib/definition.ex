defmodule Definition do
  @callback new(map) :: struct
  @callback migrate(struct) :: struct

  defmacro __using__(opts) do
    quote do
      @behaviour Definition
      @before_compile Definition

      @type t() :: %__MODULE__{}
      @schema Keyword.fetch!(unquote(opts), :schema)

      @impl Definition
      @spec new(input :: map) :: t
      def new(%{} = input) do
        map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

        struct(__MODULE__, map)
        |> migrate()
        |> Norm.conform(@schema.s())
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @impl Definition
      def migrate(arg), do: arg
    end
  end
end
