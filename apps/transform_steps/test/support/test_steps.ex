defmodule Transform.Test.Steps do
  defmodule SetStream do
    defstruct [:stream]

    defimpl Transform.Step, for: SetStream do
      def execute(step, context) do
        Transform.Steps.Context.set_stream(context, step.stream)
        |> Ok.ok()
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Transform.Step, for: TransformStream do
      def execute(step, context) do
        new_stream = Stream.map(context.stream, step.transform)

        Transform.Steps.Context.set_stream(context, new_stream)
        |> Ok.ok()
      end
    end
  end
end
