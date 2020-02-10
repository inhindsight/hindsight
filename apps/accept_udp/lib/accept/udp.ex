defmodule Accept.Udp do
  @moduledoc """
  Accept defines the structure of an accept operation
  as performed by the receive service. Accept provides
  a reference to the dataset identifier for the data to
  be received, an unique identifier for the accept operation
  and human-readable name, as well as a destination
  to write the data to.

  # Examples

  iex> Accept.Udp.new(
  ...>             version: 1,
  ...>             id: "123-456",
  ...>             dataset_id: "456-789",
  ...>             subset_id: "456-789:2020-01-28",
  ...>             destination: "gather-456-789-123-456",
  ...>             port: 8765
  ...>           )
  {:ok,
    %Accept.Udp{
             version: 1,
             id: "123-456",
             dataset_id: "456-789",
             subset_id: "456-789:2020-01-28",
             destination: "gather-456-789-123-456",
             port: 8765
           }
  }
  """
  use Definition, schema: Accept.Udp.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          destination: String.t(),
          port: integer
        }

  @derive Jason.Encoder
  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            destination: nil,
            port: nil

  defimpl Accept.Connection, for: __MODULE__ do
    def connect(accept) do
      {Accept.Udp.Socket, :start_link, [port: accept.port]}
    end
  end
end

defmodule Accept.Udp.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept.Udp{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      port: spec(is_port?())
    })
  end
end
