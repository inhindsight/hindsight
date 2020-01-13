defmodule Fake.Step do
  defstruct [:values]

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    def execute(step, context) do
      source = fn _ ->
        step.values
      end

      context
      |> set_source(source)
      |> Ok.ok()
    end
  end
end
