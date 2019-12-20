defmodule Extract do
  defmodule Context do
    @type t() :: %__MODULE__{
            response: Tesla.Env.t(),
            variables: map,
            stream: Enumerable.t()
          }
    defstruct response: nil, variables: %{}, stream: nil

    @spec new() :: %__MODULE__{}
    def new() do
      %Context{}
    end

    @spec set_response(context :: t, response :: Tesla.Env.t()) :: t
    def set_response(context, response) do
      Map.put(context, :response, response)
    end

    @spec add_variable(context :: t, name :: String.t(), value :: String.t()) :: t
    def add_variable(context, name, value) do
      new_variables = Map.put(context.variables, name, value)
      Map.put(context, :variables, new_variables)
    end

    @spec set_stream(context :: t, stream :: Enum.t()) :: t
    def set_stream(context, stream) do
      Map.put(context, :stream, stream)
    end

    @spec apply_variables(context :: t, string :: String.t) :: String.t
    def apply_variables(context, string) do
      context.variables
      |> Enum.reduce(string, fn {name, value}, buffer ->
        String.replace(buffer, "<" <> name <> ">", value)
      end)
    end
  end

  defprotocol Step do
    @spec execute(step :: t, context :: Context.t()) :: {:ok, Context.t()} | {:error, term}
    def execute(step, context)
  end

  @spec execute_steps(Enum.t()) :: {:ok, Enum.t()} | {:error, term}
  def execute_steps(steps) do
    steps
    |> parse_steps()
    |> Ok.reduce(Context.new(), &Extract.Step.execute/2)
    |> Ok.map(fn c -> c.stream end)
  rescue
    e -> {:error, error_message(e)}
  end

  defp parse_steps(steps) do
    steps
    |> Enum.map(fn step ->
      :"Elixir.#{Map.get(step, :step)}"
      |> struct!(Map.delete(step, :step))
    end)
  end

  defp error_message(e) do
    case Exception.exception?(e) do
      true -> Exception.message(e)
      false -> e
    end
  end
end
