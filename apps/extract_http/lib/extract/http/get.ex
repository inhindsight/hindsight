defmodule Extract.Http.Get do
  use Definition, schema: Extract.Http.Get.V1

  @type t :: %__MODULE__{
    version: integer,
    url: String.t(),
    headers: map
  }

  @derive Jason.Encoder
  defstruct version: 1,
            url: nil,
            headers: []

  defimpl Extract.Step, for: __MODULE__ do
    import Extract.Steps.Context

    alias Http.File.Downloader

    def execute(step, context) do
      url = apply_variables(context, step.url)
      headers = replace_variables_in_headers(context, step.headers)

      with {:ok, temp_path} <- Temp.path([]),
           {:ok, response} <- download(temp_path, url, headers) do
        context
        |> set_source(&stream_from_file(response, &1))
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
        fn line, acc -> {[line], acc} end,
        fn _acc -> File.rm!(response.destination) end
      )
    end

    defp replace_variables_in_headers(context, headers) do
      headers
      |> Enum.map(fn {name, value} -> {name, apply_variables(context, value)} end)
    end
  end
end

defmodule Extract.Http.Get.V1 do
  use Definition.Schema

  def s do
    schema(%Extract.Http.Get{
      version: version(1),
      url: required_string(),
      headers: spec(is_map())
    })
  end
end
