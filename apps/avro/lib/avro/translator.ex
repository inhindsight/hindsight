defprotocol Avro.Translator do
  @spec type(t) :: :avro.avro_type()
  def type(t)

  @spec field(t) :: :avro.record_field()
  def field(t)
end

defimpl Avro.Translator, for: Dictionary.Type.List do
  def type(%{item_type: item_type} = t) do
    struct(item_type, Map.from_struct(t))
    |> Avro.Translator.type()
    |> :avro_array.type()
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
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
end

defimpl Avro.Translator, for: Dictionary.Type.String do
  def type(_) do
    :avro_union.type([:null, :string])
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Integer do
  def type(_) do
    :avro_union.type([:null, :long])
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Float do
  def type(_) do
    :avro_union.type([:null, :double])
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Boolean do
  def type(_) do
    :avro_union.type([:null, :boolean])
  end

  def field(%{name: name} = t) do
    :avro_record.define_field(name, type(t))
  end
end
