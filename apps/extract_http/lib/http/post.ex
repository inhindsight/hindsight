defmodule Http.Post do
  @enforce_keys [:url, :body]
  defstruct url: nil,
            headers: [],
            body: nil

  defimpl Extract.Step, for: Http.Post do
    use Tesla
    import Extract.Context
    adapter Tesla.Adapter.Mint, body_as: :stream

    plug Tesla.Middleware.FollowRedirects, max_redirects: 3
    plug Tesla.Middleware.Logger, log_level: :debug

    def execute(%Http.Post{} = step, context) do
      url = apply_variables(context, step.url)
      body = apply_variables(context, step.body)
      headers = replace_variables_in_headers(context, step.headers)

      with {:ok, %Tesla.Env{status: 200} = response} <- post(url, body, headers: headers) do
        set_response(context, response)
        |> set_stream(response.body)
        |> Ok.ok()
      else
        {:ok, response} ->
          {:error, invalid_status_message(url, response)}

        {:error, reason} ->
          {:error, reason}
      end
    end

    defp invalid_status_message(url, %Tesla.Env{status: status}) do
      "HTTP POST to #{url} returned a #{status} status"
    end

    defp replace_variables_in_headers(context, headers) do
      headers
      |> Enum.map(fn {name, value} -> {name, apply_variables(context, value)} end)
    end
  end
end
