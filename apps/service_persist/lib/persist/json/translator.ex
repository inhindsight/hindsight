defprotocol Persist.Json.Translator do
  @fallback_to_any true
  @spec translate(t, value :: term) :: {:ok, term} | {:error, term}
  def translate(t, value)
end

defimpl Persist.Json.Translator, for: Any do
  def translate(_t, value), do: {:ok, value}
end

defimpl Persist.Json.Translator, for: Dictionary.Type.Timestamp do
  def translate(_t, value) do
    with {:ok, timestamp} <- NaiveDateTime.from_iso8601(value) do
      Timex.format(timestamp, "%Y-%m-%d %H:%M:%S.%-f", :strftime)
    end
  end
end

defimpl Persist.Json.Translator, for: Dictionary.Type.List do
  def translate(%{item_type: item_type}, value) do
    Ok.transform(value, &Persist.Json.Translator.translate(item_type, &1))
  end
end

defimpl Persist.Json.Translator, for: Dictionary.Type.Map do
  def translate(%{dictionary: dictionary}, value) do
    Ok.reduce(dictionary, %{}, fn field, acc ->
      Persist.Json.Translator.translate(field, Map.get(value, field.name))
      |> Ok.map(&Map.put(acc, field.name, &1))
    end)
  end
end
