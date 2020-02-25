defmodule Dictionary.Type.Timestamp do
  use Definition, schema: Dictionary.Type.Timestamp.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: "",
            format: nil

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    @tokenizer Timex.Parse.DateTime.Tokenizers.Strftime
    def normalize(_, value) when is_nil(value) or value == "" do
      Ok.ok("")
    end

    def normalize(%{format: format}, value) do
      with {:ok, date} <- Timex.parse(value, format, @tokenizer) do
        date
        |> to_iso()
        |> Ok.ok()
      end
    end

    defp to_iso(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
    defp to_iso(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  end
end

defmodule Dictionary.Type.Timestamp.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Dictionary.Type.Timestamp{
      version: version(1),
      name: required_string(),
      description: string(),
      format: required_string()
    })
  end
end
