defmodule Http.Get do
  @enforce_keys [:url]
  defstruct url: nil,
            headers: []

  defimpl Extract.Step, for: Http.Get do
    import Extract.Steps.Context

    alias Http.File.Downloader

    def execute(%Http.Get{} = step, context) do
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
