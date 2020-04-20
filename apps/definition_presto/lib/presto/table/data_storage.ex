defmodule Presto.Table.DataStorage do
  @moduledoc """
  It's more performant to write a data file directly to object storage
  than to write through PrestoDB. This behaviour defines the callbacks
  necessary to interact with object storage.
  """
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
  @moduledoc """
  Implementation of `DataStorage` behaviour to manage S3.
  """
  @behaviour Presto.Table.DataStorage
  use Properties, otp_app: :definition_presto
  require Logger

  getter(:s3_bucket, required: true)
  getter(:s3_path, required: true)

  @impl Presto.Table.DataStorage
  def upload(file_path, upload_path) do
    Logger.debug(fn -> "#{__MODULE__}: uploading file #{file_path} to #{upload_path}" end)

    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(s3_bucket(), "#{s3_path()}/#{upload_path}")
    |> ExAws.request()
  end

  @impl Presto.Table.DataStorage
  def delete(path, opts) do
    with objects <- get_all_objects("#{s3_path()}/#{path}"),
         {:ok, _} <- delete_all_objects(objects),
         true <- Keyword.get(opts, :include_directory, false),
         {:ok, _} <- delete_directory(path) do
      :ok
    else
      false -> :ok
      error_result -> error_result
    end
  end

  defp get_all_objects(path) do
    s3_bucket()
    |> ExAws.S3.list_objects(prefix: path)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
  end

  defp delete_all_objects(objects) do
    ExAws.S3.delete_all_objects(s3_bucket(), objects)
    |> ExAws.request()
  end

  defp delete_directory(path) do
    ExAws.S3.delete_object(s3_bucket(), "#{s3_path()}/#{path}/")
    |> ExAws.request()
  end
end
