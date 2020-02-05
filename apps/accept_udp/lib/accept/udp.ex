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
end

defmodule Accept.Udp.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept.Udp{
      version: version(1),
      port: spec(is_port?()),
      batch_size: spec(pos_integer?())
    })
  end
end
