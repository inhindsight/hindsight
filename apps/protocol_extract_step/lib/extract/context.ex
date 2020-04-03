defmodule Extract.Context do
  @moduledoc """
  The extraction process is a reduce, and this module is its
  accumulator.


  ## Fields

  * `response` - Response of the last action in the reduce. This field should
  be overwritten, not accumulated.
  * `variables` - A `Map` accumulation of variable names and values. These
  key/value pairs can later be referenced as part of another step in the reduce.
  * `source` - Function acting on a `Stream` of data. This can accumulate
  more functions wrapping an original function acting on the `Stream`.
  * `after_functions` - A list of functions to be executed once the extraction
  pipeline is fully executed. Think of this as the `after` block in `try/catch/after`.
  * `error_functions` - A list of functions to be executed in case an error is
  caught. Think of this as the `catch` block in `try/catch/after`.
  """
  @type source_opts :: [
          read: :lines | :bytes,
          byte_count: non_neg_integer,
          chunk_size: non_neg_integer
        ]

  @typedoc "A function that that returns a stream of chunks of extract messages"
  @type source :: (source_opts -> Enumerable.t())

  @type t() :: %__MODULE__{
          response: term,
          variables: map,
          source: source,
          after_functions: [(list -> no_return())],
          error_functions: [(() -> no_return)]
        }

  defstruct response: nil,
            variables: %{},
            source: nil,
            after_functions: [],
            error_functions: []

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

  @spec register_error_function(context :: t, (() -> no_return)) :: t
  def register_error_function(context, error_function) do
    Map.update!(context, :error_functions, fn functions ->
      functions ++ [error_function]
    end)
  end

  @spec run_error_functions(context :: t) :: t
  def run_error_functions(context) do
    context.error_functions
    |> Enum.each(fn fun -> fun.() end)

    context
  end

  @spec apply_variables(context :: t, string :: String.t()) :: String.t()
  def apply_variables(context, string) do
    context.variables
    |> Enum.reduce(string, fn {name, value}, buffer ->
      String.replace(buffer, "<" <> name <> ">", value)
    end)
  end

  @spec lines_or_bytes(source_opts) :: :line | non_neg_integer
  def lines_or_bytes(opts) do
    case Keyword.get(opts, :read) do
      nil -> :line
      :lines -> :line
      :bytes -> Keyword.get(opts, :byte_count, 100)
    end
  end

  @spec chunk_size(source_opts) :: non_neg_integer
  def chunk_size(opts) do
    Keyword.get(opts, :chunk_size, 1_000)
  end
end
