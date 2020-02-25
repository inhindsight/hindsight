defmodule Dictionary.Type.Date do
  use Definition, schema: Dictionary.Type.Date.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: "",
            format: nil

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    @tokenizer Timex.Parse.DateTime.Tokenizers.Strftime

    def normalize(_field, value) when is_nil(value) or value == "" do
      Ok.ok("")
    end

    def normalize(%{format: format}, value) do
      with {:ok, date} <- Timex.parse(value, format, @tokenizer) do
        date
        |> Date.to_iso8601()
        |> Ok.ok()
      end
    end
  end
end

defmodule Dictionary.Type.Date.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Dictionary.Type.Date{
      version: version(1),
      name: required_string(),
      description: string(),
      format: required_string()
    })
  end
end
