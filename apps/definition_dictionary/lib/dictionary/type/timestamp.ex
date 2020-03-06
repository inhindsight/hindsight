defmodule Dictionary.Type.Timestamp do
  use Definition, schema: Dictionary.Type.Timestamp.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: "",
            format: nil,
            timezone: "Etc/UTC"

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    @tokenizer Timex.Parse.DateTime.Tokenizers.Strftime
    @utc "Etc/UTC"

    def normalize(_, value) when is_nil(value) or value == "" do
      Ok.ok("")
    end

    def normalize(%{format: format, timezone: timezone}, value) do
      with {:ok, date} <- Timex.parse(value, format, @tokenizer) do
        date
        |> attach_timezone(timezone)
        |> Ok.map(&to_utc/1)
        |> Ok.map(&NaiveDateTime.to_iso8601/1)
      end
    end

    defp attach_timezone(%NaiveDateTime{} = datetime, timezone) do
      DateTime.from_naive(datetime, timezone)
    end

    defp attach_timezone(datetime, _), do: Ok.ok(datetime)

    defp to_utc(%DateTime{} = datetime) do
      DateTime.shift_zone(datetime, @utc)
    end

    defp to_utc(datetime), do: Ok.ok(datetime)
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
      format: required_string(),
      timezone: required_string()
    })
  end
end
