defmodule Extract.Http.Post do
  @moduledoc """
  An `Extract.Step.t()` impl for extracting data via RESTful POST.

  ## Init options

  * `url` - Location to POST to.
  * `headers` - Map of key/value headers to include in POST request. Defaults empty.
  * `body` - Content to be POST'd as part of request.
  """
  use Definition, schema: Extract.Http.Post.V1

  @type t :: %__MODULE__{
          version: integer,
          url: String.t(),
          headers: map,
          body: binary
        }

  @derive Jason.Encoder
  defstruct version: 1,
            url: nil,
            headers: [],
            body: nil

  defimpl Extract.Step, for: __MODULE__ do
    use Tesla
    import Extract.Context
    require Logger

    alias Extract.Http.File.Downloader

    def execute(step, context) do
      url = apply_variables(context, step.url)
      body = apply_variables(context, step.body)
      headers = replace_variables_in_headers(context, step.headers)

      with {:ok, temp_path} <- Temp.path([]),
           {:ok, response} <-
             Downloader.download(url, headers: headers, method: "POST", body: body, to: temp_path) do
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

defmodule Extract.Http.Post.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Extract.Http.Post{
      version: version(1),
      url: required_string(),
      headers: spec(is_map()),
      body: spec(is_binary())
    })
  end
end
