defmodule Test.Steps do
  defmodule CreateResponse do
    defstruct response: nil

    defimpl Extract.Step, for: CreateResponse do
      def execute(step, context) do
        {:ok, Extract.Steps.Context.set_response(context, step.response)}
      end
    end
  end

  defmodule SetVariable do
    defstruct [:name, :value]

    defimpl Extract.Step, for: SetVariable do
      def execute(step, context) do
        {:ok, Extract.Steps.Context.add_variable(context, step.name, step.value)}
      end
    end
  end

  defmodule SetStream do
    defstruct [:values]

    defimpl Extract.Step, for: SetStream do
      def execute(step, context) do
        source = fn _opts ->
          case step.values do
            nil -> context.response.body
            s -> s
          end
        end

        {:ok, Extract.Steps.Context.set_source(context, source)}
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Extract.Step, for: TransformStream do
      alias Extract.Steps.Context
      def execute(step, context) do
        source = fn opts ->
          Context.get_stream(context, opts)
          |> Stream.map(step.transform)
        end
        {:ok, Extract.Steps.Context.set_source(context, source)}
      end
    end
  end
end
