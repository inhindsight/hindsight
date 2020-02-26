defmodule Accept.Udp do
  use Definition, schema: Accept.Udp.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          port: integer
        }

  @derive Jason.Encoder
  defstruct version: 1,
            port: nil

  defimpl Accept.Connection, for: __MODULE__ do
    def connect(accept, opts) do
      {
        Accept.Udp.Socket,
        :start_link,
        [port: accept.port]
        |> Keyword.merge(opts)
      }
    end
  end
end

defmodule Accept.Udp.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept.Udp{
      version: version(1),
      port: spec(is_port?())
    })
  end
end
