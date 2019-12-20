defmodule Definition do
  @callback new(map | keyword) :: struct
  @callback from_json(String.t()) :: struct
  @callback migrate(struct) :: struct

  defmacro __using__(opts) do
    quote do
      @behaviour Definition
      @before_compile Definition

      defmodule InputError do
        defexception [:message]
      end

      @type t() :: %__MODULE__{}
      @schema Keyword.fetch!(unquote(opts), :schema)

      @impl Definition
      @spec new(input :: map | keyword) :: t
      def new(%{} = input) do
        map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

        struct(__MODULE__, map)
        |> migrate()
        |> Norm.conform(@schema.s())
      end

      def new(input) when is_list(input) do
        case Keyword.keyword?(input) do
          true ->
            Map.new(input) |> new()

          false ->
            {:error, InputError.exception(message: input)}
        end
      end

      @impl Definition
      @spec from_json(input :: String.t()) :: t
      def from_json(input) when is_binary(input) do
        with {:ok, map} <- Jason.decode(input) do
          new(map)
        end
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
