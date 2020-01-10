defmodule Http.Post do
  @enforce_keys [:url, :body]
  defstruct url: nil,
            headers: [],
            body: nil

  defimpl Extract.Step, for: Http.Post do
    use Tesla
    import Extract.Steps.Context
    alias Http.File.Downloader

    def execute(%Http.Post{} = step, context) do
      url = apply_variables(context, step.url)
      body = apply_variables(context, step.body)
      headers = replace_variables_in_headers(context, step.headers)

      with {:ok, temp_path} <- Temp.path([]),
           {:ok, response} <-
             Downloader.download(url, headers: headers, method: "POST", body: body, to: temp_path) do
        context
        |> set_source(&stream_from_file(response, &1))
        |> Ok.ok()
      end
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
