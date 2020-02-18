defmodule Extract.Context do
  @type source_opts :: [
          read: :lines | :bytes,
          byte_count: integer()
        ]

  @type source :: (source_opts -> Enumerable.t())

  @type t() :: %__MODULE__{
          response: term,
          variables: map,
          source: source,
          after_functions: [(list -> no_return())]
        }
  defstruct response: nil, variables: %{}, source: nil, after_functions: []

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{source: fn _ -> [] end}
  end

  @spec get_stream(context :: t, source_opts) :: Enumerable.t()
  def get_stream(%__MODULE__{source: function}, opts \\ []) when is_function(function, 1) do
    function.(opts)
  end

  @spec set_response(context :: t, response :: term) :: t
  def set_response(context, response) do
    Map.put(context, :response, response)
  end

  @spec add_variable(context :: t, name :: String.t(), value :: String.t()) :: t
  def add_variable(context, name, value) do
    new_variables = Map.put(context.variables, name, value)
    Map.put(context, :variables, new_variables)
  end

  @spec set_source(context :: t, source) :: t
  def set_source(context, source) do
    Map.put(context, :source, source)
  end

  @spec register_after_function(context :: t, (list -> no_return)) :: t
  def register_after_function(context, after_function) do
    Map.update!(context, :after_functions, fn functions ->
      functions ++ [after_function]
    end)
  end

  @spec run_after_functions(context :: t, list) :: t
  def run_after_functions(context, messages) do
    context.after_functions
    |> Enum.each(fn fun ->
      fun.(messages)
    end)

    context
  end

  @spec apply_variables(context :: t, string :: String.t()) :: String.t()
  def apply_variables(context, string) do
    context.variables
    |> Enum.reduce(string, fn {name, value}, buffer ->
      String.replace(buffer, "<" <> name <> ">", value)
    end)
  end

  @spec lines_or_bytes(source_opts) :: :line | integer()
  def lines_or_bytes(opts) do
    case Keyword.get(opts, :read) do
      nil -> :line
      :lines -> :line
      :bytes -> Keyword.get(opts, :byte_count, 100)
    end
  end
end
