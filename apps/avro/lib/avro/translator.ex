defprotocol Avro.Translator do
  @spec translate_type(t) :: :avro.record_field()
  def translate_type(t)
end

defimpl Avro.Translator, for: Dictionary.Type.String do
  @nullable_string :avro_union.type([:null, :string])
  def translate_type(%{name: name}) do
    :avro_record.define_field(name, @nullable_string)
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Integer do
  @nullable_long :avro_union.type([:null, :long])
  def translate_type(%{name: name}) do
    :avro_record.define_field(name, @nullable_long)
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Float do
  @nullable_double :avro_union.type([:null, :double])
  def translate_type(%{name: name}) do
    :avro_record.define_field(name, @nullable_double)
  end
end

defimpl Avro.Translator, for: Dictionary.Type.Boolean do
  @nullable_boolean :avro_union.type([:null, :boolean])
  def translate_type(%{name: name}) do
    :avro_record.define_field(name, @nullable_boolean)
  end
end
