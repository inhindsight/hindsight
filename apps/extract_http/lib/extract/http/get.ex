defmodule Extract.Http.Get do
  @moduledoc """
  An `Extract.Step.t()` impl for extracting data via RESTful GET.

  ## Init options

  * `url` - Location to extract data from.
  * `headers` - Map of key/value headers to include in the GET request. Defaults empty.
  """
  use Definition, schema: Extract.Http.Get.V1
  use JsonSerde, alias: "extract_http_get"

  @type t :: %__MODULE__{
          version: integer,
          url: String.t(),
          headers: map
        }

  @derive Jason.Encoder
  defstruct version: 1,
            url: nil,
            headers: %{}

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Context
    require Logger

    alias Extract.Http.File.Downloader

    def execute(step, context) do
      url = apply_variables(context, step.url)
      headers = replace_variables_in_headers(context, step.headers)

      with {:ok, temp_path} <- Temp.path([]),
           {:ok, response} <- download(temp_path, url, headers) do
        context
        |> set_source(&stream_from_file(response, &1))
        |> register_error_function(fn ->
          File.rm(response.destination)
          |> Ok.map_if_error(
            &Logger.warn(fn -> "#{__MODULE__}: Failed to cleanup file #{inspect(&1)}" end)
          )
        end)
        |> Ok.ok()
      end
    end

    defp download(path, url, headers) do
      Downloader.download(url, to: path, headers: headers)
    end

    defp stream_from_file(response, opts) do
      response.destination
      |> File.stream!([], lines_or_bytes(opts))
      |> Stream.transform(
        fn -> :ok end,
        fn line, acc -> {[Extract.Message.new(data: line)], acc} end,
        fn _acc -> File.rm!(response.destination) end
      )
      |> Stream.chunk_every(chunk_size(opts))
    end

    defp replace_variables_in_headers(context, headers) do
      headers
      |> Enum.map(fn {name, value} -> {name, apply_variables(context, value)} end)
    end
  end
end

defmodule Extract.Http.Get.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Http.Get{
      version: version(1),
      url: required_string(),
      headers: spec(is_map())
    })
  end
end
