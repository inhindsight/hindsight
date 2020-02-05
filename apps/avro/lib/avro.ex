defmodule Avro do
  @type t :: %__MODULE__{
          file_path: String.t(),
          file: File.io_device(),
          lkup: :avro.lkup_fun(),
          schema: :avro.record_type(),
          header: :avro_ocf.header(),
          dictionary: Dictionary.t()
        }

  defstruct [:file_path, :file, :lkup, :schema, :header, :dictionary]

  @spec open(String.t(), Dictionary.t()) :: {:ok, t} | {:error, term}
  def open(name, dictionary) do
    with {:ok, file_path} <- Temp.path(),
         {:ok, file} <- File.open(file_path, [:write]) do
      schema = create_schema(name, dictionary)
      header = :avro_ocf.make_header(schema)
      :ok = :avro_ocf.write_header(file, header)

      %__MODULE__{
        file_path: file_path,
        file: file,
        schema: schema,
        lkup: :avro.make_lkup_fun(schema),
        header: header,
        dictionary: dictionary
      }
      |> Ok.ok()
    end
  rescue
    e -> {:error, e}
  end

  @spec write(t, :avro.in()) :: {:ok, non_neg_integer} | {:error, term}
  def write(avro, data) do
    with {:ok, transformed_data} <- Ok.transform(data, &transform_data(avro.dictionary, &1)) do
      :avro_ocf.append_file(avro.file, avro.header, avro.lkup, avro.schema, transformed_data)
      %{size: size} = File.stat!(avro.file_path)
      Ok.ok(size)
    end
  rescue
    e -> {:error, e}
  end

  @spec close(t) :: String.t()
  def close(avro) do
    File.close(avro.file)
    avro.file_path
  end

  defp transform_data(dictionary, datum) do
    Ok.reduce(dictionary, datum, fn field, row ->
      Avro.Translator.value(field, Map.get(row, field.name))
      |> Ok.map(&Map.put(row, field.name, &1))
    end)
  end

  defp create_schema(name, dictionary) do
    fields = Enum.map(dictionary, &Avro.Translator.field/1)
    :avro_record.type(name, fields)
  end
end
