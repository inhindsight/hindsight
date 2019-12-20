defmodule Http.Header do
  @enforce_keys [:name, :into]
  defstruct [:name, :into]

  defimpl Extract.Step, for: Http.Header do
    require Logger
    import Extract.Context

    def execute(%Http.Header{} = step, context) do
      case context.response do
        nil ->
          Logger.warn("#{__MODULE__}: No response is available to execute step: #{inspect(step)}")
          Ok.ok(context)

        response ->
          value = Tesla.get_header(response, step.name)

          add_variable(context, step.into, value)
          |> Ok.ok()
      end
    end
  end
end
