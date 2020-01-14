defmodule Definition do
  @callback new(map | keyword) :: {:ok, struct} | {:error, term}
  @callback new!(map | keyword) :: struct
  @callback from_json(String.t()) :: {:ok, struct} | {:error, term}
  @callback schema() :: %Norm.Schema{}
  @callback on_new(struct) :: {:ok, struct} | {:error, term}
  @callback migrate(struct) :: {:ok, struct} | {:error, term}

  defmacro __using__(opts) do
    quote do
      @behaviour Definition
      @before_compile Definition

      defmodule InputError do
        defexception [:message]
      end

      @schema Keyword.fetch!(unquote(opts), :schema)

      @impl Definition
      def new(%{} = input) do
        map = for {key, val} <- input, do: {:"#{key}", val}, into: %{}

        struct(__MODULE__, map)
        |> on_new()
        |> Ok.map(&migrate/1)
        |> Ok.map(&Norm.conform(&1, @schema.s()))
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
      def new!(input) do
        case new(input) do
          {:ok, value} -> value
          {:error, reason} -> raise reason
        end
      end

      @impl Definition
      def on_new(input) do
        {:ok, input}
      end

      @impl Definition
      def from_json(input) when is_binary(input) do
        with {:ok, map} <- Jason.decode(input) do
          new(map)
        end
      end

      @impl Definition
      def schema do
        @schema.s()
      end

      defoverridable on_new: 1
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @impl Definition
      def migrate(arg), do: {:ok, arg}
    end
  end
end
