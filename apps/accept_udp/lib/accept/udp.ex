defmodule Accept.Udp do
  use Definition, schema: Accept.Udp.V1

  @type t :: %__MODULE__{
          version: integer,
          port: integer
        }

  @derive Jason.Encoder
  defstruct version: 1,
            port: nil
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
