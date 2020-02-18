defmodule Accept.Websocket do
  use Definition, schema: Accept.Websocket.V1

  @derive Jason.Encoder
  defstruct version: 1,
            path: nil,
            port: nil

  defimpl Accept.Connection, for: __MODULE__ do
    def connect(accept, opts) do
      {Accept.Websocket.Supervisor, [path: accept.path, port: accept.port] ++ opts}
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
      port: spec(is_port?())
    })
  end
end
