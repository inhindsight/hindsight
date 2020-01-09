defmodule Fake.Step do
  defstruct [:values]

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    def execute(step, context) do
      set_stream(context, step.values)
      |> Ok.ok()
    end
  end
end
