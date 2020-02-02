defmodule Avro do

  @type t :: %__MODULE__{
    file_path: String.t(),
    file: File.t(),
    lkup: :avro.lkup_fun(),
    schema: :avro.record_type(),
    header: :avro.header()
  }

  defstruct [:file_path, :file, :lkup, :schema, :header]

  @spec open(String.t(), Dictionary.t()) :: t
  def open(name, dictionary) do
    file_path = "a.out"
    schema = create_schema(name, dictionary)
    header = :avro_ocf.make_header(schema)
    file = File.open!(file_path, [:write])
    :ok = :avro_ocf.write_header(file, header)

    %__MODULE__{
      file_path: file_path,
      file: file,
      schema: schema,
      lkup: :avro.make_lkup_fun(schema),
      header: header
    }
    |> Ok.ok()
  end

  @spec write(t, :avro.in()) :: :ok
  def write(avro, data) do
    :avro_ocf.append_file(avro.file, avro.header, avro.lkup, avro.schema, data)
    %{size: size} = File.stat!(avro.file_path)
    Ok.ok(size)
  end

  @spec close(t) :: String.t()
  def close(avro) do
    File.close(avro.file)
    avro.file_path
  end

  defp create_schema(name, dictionary) do
    fields = Enum.map(dictionary, &Avro.Translator.translate_type/1)
    :avro_record.type(name, fields)
  end

end
