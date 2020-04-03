defmodule Test.Steps do
  defmodule CreateResponse do
    defstruct response: nil

    defimpl Extract.Step, for: CreateResponse do
      def execute(step, context) do
        {:ok, Extract.Context.set_response(context, step.response)}
      end
    end
  end

  defmodule SetVariable do
    defstruct [:name, :value]

    defimpl Extract.Step, for: SetVariable do
      def execute(step, context) do
        {:ok, Extract.Context.add_variable(context, step.name, step.value)}
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
          |> Enum.map(fn x -> %Extract.Message{data: x} end)
          |> Enum.chunk_every(2)
        end

        {:ok, Extract.Context.set_source(context, source)}
      end
    end
  end

  defmodule TransformStream do
    defstruct [:transform]

    defimpl Extract.Step, for: TransformStream do
      alias Extract.Context

      def execute(step, context) do
        source = fn opts ->
          Context.get_stream(context, opts)
          |> Stream.map(fn chunk ->
            Enum.map(chunk, &Extract.Message.update_data(&1, step.transform))
          end)
        end

        {:ok, Extract.Context.set_source(context, source)}
      end
    end
  end

  defmodule RegisterFunctions do
    defstruct [:after, :error]

    defimpl Extract.Step do
      alias Extract.Context

      def execute(step, context) do
        context =
          case step.after do
            nil -> context
            f -> Context.register_after_function(context, f)
          end

        context =
          case step.error do
            nil -> context
            f -> Context.register_error_function(context, f)
          end

        {:ok, context}
      end
    end
  end
end
