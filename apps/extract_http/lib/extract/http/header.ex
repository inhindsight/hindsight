defmodule Extract.Http.Header do
  use Definition, schema: Extract.Http.Header.V1

  @type t :: %__MODULE__{
    version: integer,
    name: String.t(),
    into: String.t()
  }

  @derive Jason.Encoder
  defstruct version: 1, name: nil, into: nil

  defmodule HeaderNotAvailableError do
    defexception message: "Header not available",
                 header: nil,
                 response: nil
  end

  defimpl Extract.Step, for: __MODULE__ do
    require Logger
    import Extract.Steps.Context

    def execute(step, context) do
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

defmodule Extract.Http.Header.V1 do
  use Definition.Schema

  def s do
    schema(%Extract.Http.Header{
      version: version(1),
      name: required_string(),
      into: required_string()
    })
  end
end
