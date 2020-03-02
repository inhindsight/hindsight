defmodule Persist.DataFile do
  use Properties, otp_app: :service_persist
  @type t :: term
  @type file_path :: Path.t()

  @type format :: :json | :orc | :avro

  @callback format() :: format
  @callback open(destination :: String.t(), dictionary :: Dictionary.t()) ::
              {:ok, t} | {:error, term}
  @callback write(t, messages :: list()) :: {:ok, non_neg_integer} | {:error, term}
  @callback close(t) :: file_path

  getter(:impl, default: Persist.DataFile.Json)

  @spec format() :: format
  def format() do
    impl().format()
  end

  @spec open(String.t(), Dictionary.t()) :: {:ok, t} | {:error, term}
  def open(destination, dictionary) do
    impl().open(destination, dictionary)
  end

  @spec write(t, list()) :: {:ok, non_neg_integer} | {:error, term}
  def write(t, messages) do
    impl().write(t, messages)
  end

  @spec close(t) :: file_path
  def close(t) do
    impl().close(t)
  end
end

defmodule Persist.DataFile.Avro do
  @behaviour Persist.DataFile

  def format(), do: :avro

  defdelegate open(destination, dictionary), to: Avro
  defdelegate write(avro, data), to: Avro
  defdelegate close(avro), to: Avro
end

defmodule Persist.DataFile.Json do
  @behaviour Persist.DataFile

  @type t :: %__MODULE__{
          file_path: Path.t(),
          file: :file.io_device()
        }

  defstruct [:file_path, :file]

  @impl true
  def format(), do: :json

  @impl true
  def open(_destination, _dictionary) do
    with {:ok, path} <- Temp.path(%{suffix: ".gz"}),
         {:ok, file} <- :file.open(path, [:write, :raw, :delayed_write, :compressed]) do
      %__MODULE__{
        file_path: path,
        file: file
      }
      |> Ok.ok()
    end
  end

  @impl true
  def write(t, data) do
    with :ok <- Ok.each(data, &write_record(t, &1)) do
      File.stat!(t.file_path)
      |> Map.get(:size)
      |> Ok.ok()
    end
  end

  @impl true
  def close(t) do
    :file.close(t.file)
    t.file_path
  end

  defp write_record(t, record) do
    with {:ok, encoded_record} <- Jason.encode(record) do
      :file.write(t.file, encoded_record <> "\n")
    end
  end
end
