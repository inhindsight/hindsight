defmodule Http.Get do
  @enforce_keys [:url]
  defstruct url: nil,
            headers: []

  defimpl Extract.Step, for: Http.Get do
    use Tesla
    import Extract.Steps.Context
    adapter Tesla.Adapter.Mint, body_as: :stream

    plug Tesla.Middleware.FollowRedirects, max_redirects: 3
    plug Tesla.Middleware.Logger, log_level: :debug

    def execute(%Http.Get{} = step, context) do
      url = apply_variables(context, step.url)
      headers = replace_variables_in_headers(context, step.headers)

      case get(url, headers: headers) do
        {:ok, %Tesla.Env{status: 200} = response} ->
          set_response(context, response)
          |> set_stream(response.body)
          |> Ok.ok()

        {:ok, response} ->
          {:error, invalid_status_message(url, response)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp invalid_status_message(url, %Tesla.Env{status: status}) do
      "HTTP GET to #{url} returned a #{status} status"
    end

    defp replace_variables_in_headers(context, headers) do
      headers
      |> Enum.map(fn {name, value} -> {name, apply_variables(context, value)} end)
    end
  end
end
