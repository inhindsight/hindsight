defmodule Test.Steps do
  defmodule CreateResponse do
    defstruct response: nil

    defimpl Extract.Step, for: CreateResponse do
      def execute(step, context) do
        Extract.Context.set_response(context, step.response)
      end
    end
  end

  defmodule SetVariable do
    defstruct [:name, :value]

    defimpl Extract.Step, for: SetVariable do
      def execute(step, context) do
        Extract.Context.add_variable(context, step.name, step.value)
      end
    end
  end

  defmodule SetStream do
    defstruct [:stream]

    defimpl Extract.Step, for: SetStream do
      def execute(step, context) do
        stream =
          case step.stream do
            nil -> context.response.body
            s -> s
          end

        Extract.Context.set_stream(context, stream)
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Extract.Step, for: TransformStream do
      def execute(step, context) do
        new_stream = Stream.map(context.stream, step.transform)
        Extract.Context.set_stream(context, new_stream)
      end
    end
  end
end
