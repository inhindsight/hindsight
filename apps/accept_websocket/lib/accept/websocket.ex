defmodule Accept.Websocket do
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
        [
          path: accept.path,
          port: accept.port,
          idle_timeout: accept.idle_timeout,
          hibernate: accept.hibernate
        ] ++ opts
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
