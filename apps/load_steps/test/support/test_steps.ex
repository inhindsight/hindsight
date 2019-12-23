defmodule Test.Steps do
  defmodule SetStream do
    defstruct [:stream]

    defimpl Load.Step, for: SetStream do
      def execute(step, context) do
        Load.Steps.Context.set_stream(context, step.stream)
        |> Ok.ok()
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Load.Step, for: TransformStream do
      def execute(step, context) do
        new_stream = Stream.map(context.stream, step.transform)

        Load.Steps.Context.set_stream(context, new_stream)
        |> Ok.ok()
      end
    end
  end
end
