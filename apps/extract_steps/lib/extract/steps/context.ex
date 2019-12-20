defmodule Extract.Steps.Context do
  @type t() :: %__MODULE__{
    response: Tesla.Env.t(),
    variables: map,
    stream: Enumerable.t()
  }
  defstruct response: nil, variables: %{}, stream: nil

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{}
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

  @spec apply_variables(context :: t, string :: String.t()) :: String.t()
  def apply_variables(context, string) do
    context.variables
    |> Enum.reduce(string, fn {name, value}, buffer ->
      String.replace(buffer, "<" <> name <> ">", value)
    end)
  end
end
