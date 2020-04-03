defmodule Accept.Websocket do
  @moduledoc """
  A WebSocket connection for data being pushed to Hindsight.

  ## Configuration

  * `path` - Required. Path of WebSocket endpoint.
  * `port` - Required. Port on which the WebSocket can be reached.
  * `idle_timeout` - Timeout in milliseconds. Defaults to 3 minutes.
  * `hibernate` - Defaults to false.
  """
  use Definition, schema: Accept.Websocket.V1

  @derive Jason.Encoder
  defstruct version: 1,
            path: nil,
            port: nil,
            idle_timeout: 180_000,
            hibernate: false

  defimpl Accept.Connection, for: __MODULE__ do
    def connect(accept, opts) do
      {
        Accept.Websocket.Supervisor,
        :start_link,
        [
          path: accept.path,
          port: accept.port,
          idle_timeout: accept.idle_timeout,
          hibernate: accept.hibernate
        ]
        |> Keyword.merge(opts)
      }
    end
  end
end

defmodule Accept.Websocket.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept.Websocket{
      version: version(1),
      path: required_string(),
      port: spec(is_port?()),
      idle_timeout: spec(is_integer() and (&(&1 > 0))),
      hibernate: spec(is_boolean())
    })
  end
end
