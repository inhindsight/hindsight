defmodule Fake.Step do
  defstruct [:values, :pid]

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context

    def execute(step, context) do
      source = fn _ ->
        step.values
        |> Stream.map(&Extract.Message.new(data: &1))
      end

      context
      |> register_after_function(fn msgs ->
        send(step.pid, {:after, msgs})
      end)
      |> set_source(source)
      |> Ok.ok()
    end
  end
end
