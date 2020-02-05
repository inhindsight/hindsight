defmodule Accept do
  @moduledoc """
  Accept defines the structure of an accept operation
  as performed by the receive service. Accept provides
  a reference to the dataset identifier for the data to
  be received, an unique identifier for the accept operation
  and human-readable name, as well as a destination
  to write the data to.

  # Examples

    iex> Accept.new(
    ...>             version: 1,
    ...>             id: "123-456",
    ...>             dataset_id: "456-789",
    ...>             name: "456-789:2020-01-28",
    ...>             destination: "gather-456-789-123-456",
    ...>             connection: %Accept.SampleProtocol{port: 5555, key: "foobar", batch: 1_000}
    ...>           )
    {:ok,
      %Accept{
               version: 1,
               id: "123-456",
               dataset_id: "456-789",
               name: "456-789:2020-01-28",
               destination: "gather-456-789-123-456",
               connection: %Accept.SampleProtocol{port: 5555, key: "foobar", batch: 1_000}
             }
    }
  """
  use Definition, schema: Accept.V1

  @type uuid :: String.t()

  @type t :: %Accept{
          version: integer,
          id: uuid,
          dataset_id: uuid,
          name: String.t(),
          destination: String.t(),
          connection: Accept.Udp.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            name: nil,
            destination: nil,
            connection: nil
end
