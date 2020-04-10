defprotocol Presto.Table.Json.Translator do
  @moduledoc """
  Protocol for formatting Hindsight `Dictionary.Type`s into proper
  JSON during the write process.
  """
  @fallback_to_any true
  @spec translate(t, value :: term) :: {:ok, term} | {:error, term}
  def translate(t, value)
end

defimpl Presto.Table.Json.Translator, for: Any do
  @moduledoc false
  def translate(_t, value), do: {:ok, value}
end

defimpl Presto.Table.Json.Translator, for: Dictionary.Type.Timestamp do
  @moduledoc false
  def translate(_t, value) do
    with {:ok, timestamp} <- NaiveDateTime.from_iso8601(value) do
      Timex.format(timestamp, "%Y-%m-%d %H:%M:%S.%-f", :strftime)
    end
  end
end

defimpl Presto.Table.Json.Translator, for: Dictionary.Type.List do
  @moduledoc false
  def translate(%{item_type: item_type}, value) do
    Ok.transform(value, &Presto.Table.Json.Translator.translate(item_type, &1))
  end
end

defimpl Presto.Table.Json.Translator, for: Dictionary.Type.Map do
  @moduledoc false
  def translate(%{dictionary: dictionary}, value) do
    Ok.reduce(dictionary, %{}, fn field, acc ->
      Presto.Table.Json.Translator.translate(field, Map.get(value, field.name))
      |> Ok.map(&Map.put(acc, field.name, &1))
    end)
  end
end
