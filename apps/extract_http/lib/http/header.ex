defmodule Http.Header do
  @enforce_keys [:name, :into]
  defstruct [:name, :into]

  defmodule HeaderNotAvailableError do
    defexception message: "Header not available",
                 header: nil,
                 response: nil
  end

  defimpl Extract.Step, for: Http.Header do
    require Logger
    import Extract.Context

    def execute(%Http.Header{} = step, context) do
      with {:response, %Tesla.Env{} = response} <- {:response, context.response},
           {:header, value} when value != nil <- {:header, Tesla.get_header(response, step.name)} do
        value = Tesla.get_header(response, step.name)

        add_variable(context, step.into, value)
        |> Ok.ok()
      else
        {:response, _} ->
          Extract.InvalidContextError.exception(
            message: "Response is not available in context.",
            step: step
          )
          |> Ok.error()

        {:header, _} ->
          HeaderNotAvailableError.exception(
            header: step.name,
            response: context.response
          )
          |> Ok.error()
      end
    end
  end
end
