defmodule Presto.Table.DataStorage do
  use Properties, otp_app: :definition_presto

  @callback upload(file_path :: String.t(), upload_path :: String.t()) ::
              {:ok, term} | {:error, term}

  @callback delete(path :: String.t(), opts :: keyword) :: :ok | {:error, term}

  getter(:impl, default: Presto.Table.DataStorage.S3)

  def upload(file_path, upload_path) do
    impl().upload(file_path, upload_path)
  end

  def delete(path, opts \\ []) do
    impl().delete(path, opts)
  end
end

defmodule Presto.Table.DataStorage.S3 do
  @behaviour Presto.Table.DataStorage
  use Properties, otp_app: :definition_presto

  getter(:s3_bucket, required: true)
  getter(:s3_path, required: true)

  @impl Presto.Table.DataStorage
  def upload(file_path, upload_path) do
    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(s3_bucket(), "#{s3_path()}/#{upload_path}")
    |> ExAws.request()
  end

  @impl Presto.Table.DataStorage
  def delete(path, opts) do
    stream =
      s3_bucket()
      |> ExAws.S3.list_objects(prefix: "#{s3_path()}/#{path}/")
      |> ExAws.stream!()
      |> Stream.map(& &1.key)

    ExAws.S3.delete_all_objects(s3_bucket(), stream)
    |> ExAws.request()
    |> Ok.map(fn _ ->
      case Keyword.get(opts, :include_directory, false) do
        true -> delete_directory(path)
        false -> :ok
      end
    end)
  end

  defp delete_directory(path) do
    ExAws.S3.delete_object(s3_bucket(), "#{s3_path()}/#{path}/")
    |> ExAws.request()
    |> Ok.map(fn _ -> :ok end)
  end
end
