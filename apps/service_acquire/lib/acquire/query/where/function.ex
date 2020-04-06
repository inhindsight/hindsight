defmodule Acquire.Query.Where.Function do
  @moduledoc false
  use Definition, schema: Acquire.Query.Where.Function.Schema

  @type t :: %__MODULE__{
          function: String.t(),
          args: [Acquire.Queryable.t()]
        }

  defstruct [:function, :args]

  defimpl Acquire.Queryable, for: __MODULE__ do
    @operators ["=", ">", "<", ">=", "<=", "!="]

    def parse_statement(fun) do
      arguments = Enum.map(fun.args, &Acquire.Queryable.parse_statement/1)
      to_statement(fun.function, arguments)
    end

    def parse_input(fun) do
      Enum.map(fun.args, &Acquire.Queryable.parse_input/1)
      |> List.flatten()
      |> Enum.filter(& &1)
    end

    defp to_statement(fun, [arg1, arg2 | _]) when fun in @operators do
      "#{arg1} #{fun} #{arg2}"
    end

    defp to_statement(fun, arguments) do
      "#{fun}(#{Enum.join(arguments, ", ")})"
    end
  end
end

defmodule Acquire.Query.Where.Function.Schema do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.Where.Function{
      function: required_string(),
      args: spec(is_list())
    })
  end
end
