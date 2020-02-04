defmodule Avro do
  @type t :: %__MODULE__{
          file_path: String.t(),
          file: File.t(),
          lkup: :avro.lkup_fun(),
          schema: :avro.record_type(),
          header: :avro.header()
        }

  defstruct [:file_path, :file, :lkup, :schema, :header]

  @spec open(String.t(), Dictionary.t()) :: {:ok, t} | {:error, term}
  def open(name, dictionary) do
    with {:ok, file_path} <- Temp.path(suffix: "avro"),
         {:ok, file} <- File.open(file_path, [:write]) do
      schema = create_schema(name, dictionary)
      header = :avro_ocf.make_header(schema)
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
  rescue
    e -> {:error, e}
  end

  @spec write(t, :avro.in()) :: {:ok, non_neg_integer} | {:error, term}
  def write(avro, data) do
    :avro_ocf.append_file(avro.file, avro.header, avro.lkup, avro.schema, data)
    %{size: size} = File.stat!(avro.file_path)
    Ok.ok(size)
  rescue
    e -> {:error, e}
  end

  @spec close(t) :: String.t()
  def close(avro) do
    File.close(avro.file)
    avro.file_path
  end

  defp create_schema(name, dictionary) do
    fields = Enum.map(dictionary, &Avro.Translator.field/1)
    :avro_record.type(name, fields)
  end
end
