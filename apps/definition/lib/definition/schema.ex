defmodule Definition.Schema do
  @callback s() :: %Norm.Schema{}

  defmacro __using__(_) do
    quote do
      @behaviour Definition.Schema

      import Norm
      import Definition.Schema.Validation
    end
  end
end
