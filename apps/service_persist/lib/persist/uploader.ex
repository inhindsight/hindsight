defmodule Persist.Uploader do
  use Properties, otp_app: :service_persist

  @callback upload(file_path :: String.t(), upload_path :: String.t()) ::
              {:ok, term} | {:error, term}

  getter(:impl, default: Persist.Uploader.S3)

  def upload(file_path, upload_path) do
    impl().upload(file_path, upload_path)
  end
end

defmodule Persist.Uploader.S3 do
  @behaviour Persist.Uploader
  use Properties, otp_app: :service_persist

  getter(:s3_bucket, required: true)
  getter(:s3_path, required: true)

  @impl Persist.Uploader
  def upload(file_path, upload_path) do
    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(s3_bucket(), "#{s3_path()}/#{upload_path}")
    |> ExAws.request()
  end
end
