defmodule Persist.DataStorage do
  use Properties, otp_app: :service_persist

  @callback upload(file_path :: String.t(), upload_path :: String.t()) ::
              {:ok, term} | {:error, term}

  @callback delete(path :: String.t()) :: :ok | {:error, term}

  getter(:impl, default: Persist.DataStorage.S3)

  def upload(file_path, upload_path) do
    impl().upload(file_path, upload_path)
  end

  def delete(path) do
    impl().delete(path)
  end
end

defmodule Persist.DataStorage.S3 do
  @behaviour Persist.DataStorage
  use Properties, otp_app: :service_persist

  getter(:s3_bucket, required: true)
  getter(:s3_path, required: true)

  @impl Persist.DataStorage
  def upload(file_path, upload_path) do
    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(s3_bucket(), "#{s3_path()}/#{upload_path}")
    |> ExAws.request()
  end

  @impl Persist.DataStorage
  def delete(path) do
    stream =
      s3_bucket()
      |> ExAws.S3.list_objects(prefix: "#{s3_path()}/#{path}/")
      |> ExAws.stream!()
      |> Stream.map(& &1.key)

    ExAws.S3.delete_all_objects(s3_bucket(), stream)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      error_result -> error_result
    end
  end
end
