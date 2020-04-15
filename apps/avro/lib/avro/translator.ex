defprotocol Avro.Translator do
  @spec type(t) :: :avro.avro_type()
  def type(t)

  @spec field(t) :: :avro.record_field()
  def field(t)

  @spec value(t, value :: term) :: {:ok, term} | {:error, term}
  def value(t, value)
end

defmodule Avro.Translator.Default do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def type(_t), do: :avro_primitive.null_type()

      def field(%{name: name} = t) do
        :avro_record.define_field(name, type(t))
      end

      def value(_, value), do: Ok.ok(value)

      defoverridable type: 1, field: 1, value: 2
    end
  end
end

defimpl Avro.Translator, for: Dictionary.Type.List do
  def type(%{item_type: item_type}) do
    item_type
    |> Avro.Translator.type()
    |> :avro_array.type()
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end

  def value(%{item_type: item_type}, values) do
    Ok.transform(values, &Avro.Translator.value(item_type, &1))
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Map do
  def type(%{dictionary: dictionary}) do
    fields = Enum.map(dictionary, &Avro.Translator.field/1)
    record = :avro_record.type("record_0", fields)
    :avro_union.type([:null, record])
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end

  def value(%{dictionary: dictionary}, map) do
    Ok.reduce(dictionary, %{}, fn field, acc ->
      Avro.Translator.value(field, Map.get(map, field.name))
      |> Ok.map(fn new_value -> Map.put(acc, field.name, new_value) end)
    end)
  end
end

defimpl Avro.Translator, for: Dictionary.Type.String do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:string, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Wkt.Point do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:string, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Integer do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:long, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Float do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:double, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Latitude do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:double, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Longitude do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:double, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Boolean do
  use Avro.Translator.Default

  def type(_) do
    :avro_union.type([:boolean, :null])
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Date do
  use Avro.Translator.Default
  @epoch Date.new(1970, 1, 1) |> elem(1)

  def type(_) do
    date = :avro_primitive.type(:int, [{"logicalType", "date"}])
    :avro_union.type([date, :null])
  end

  def value(_, iso_date) do
    Date.from_iso8601(iso_date)
    |> Ok.map(&Date.diff(&1, @epoch))
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Timestamp do
  use Avro.Translator.Default
  @epoch DateTime.from_unix!(0) |> DateTime.to_naive()

  def type(_) do
    timestamp = :avro_primitive.type(:long, [{"logicalType", "timestamp-millis"}])
    :avro_union.type([timestamp, :null])
  end

  def value(_, iso_timestamp) do
    with {:ok, timestamp} <- NaiveDateTime.from_iso8601(iso_timestamp) do
      NaiveDateTime.diff(timestamp, Timex.to_naive_datetime(@epoch), :millisecond)
      |> Ok.ok()
    end
  end
end
