defmodule Extract do
  defmodule Context do
    @type t() :: %__MODULE__{
            response: Tesla.Env.t(),
            variables: map,
            stream: Enumerable.t
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
  end

  defprotocol Step do
    @spec execute(step :: t, context :: Context.t()) :: Context.t()
    def execute(step, context)
  end

  @spec execute_steps(steps :: list) :: {:ok, Enum.t} | {:error, term}
  def execute_steps(steps) do
    context =
      steps
      |> parse_steps()
      |> Enum.reduce(Context.new(), &Extract.Step.execute/2)

    {:ok, context.stream}
  rescue
    e -> {:error, error_message(e)}
  end

  defp parse_steps(steps) do
    steps
    |> Enum.map(fn step ->
      struct = :"Elixir.#{Map.get(step, :step)}"
      struct!(struct, Map.delete(step, :step))
    end)
  end

  defp error_message(e) do
    case Exception.exception?(e) do
      true -> Exception.message(e)
      false -> e
    end
  end
end
