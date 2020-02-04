defmodule Accept.Udp do
  use Definition, schema: Accept.Udp.V1

  @type t :: %__MODULE__{
          version: integer,
          port: integer,
          batch_size: integer
        }

  @derive Jason.Encoder
  defstruct version: 1,
    port: nil,
  batch_size: nil

  defimpl Accept.Connection, for: __MODULE__ do
    def connect(settings) do
      [port: settings.port, batch_size: settings.batch_size]
    end
  end
end

defmodule Receive.Udp.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept.Udp{
      version: version(1),
      port: spec(is_integer() and &(&1 <= 65_535)),
      batch_size: spec(pos_integer?())
    })
  end
end
