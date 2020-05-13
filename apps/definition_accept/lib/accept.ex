defmodule Accept do
  @moduledoc """
  Accept defines the structure of an accept operation
  as performed by the receive service. Accept provides
  a reference to the dataset identifier for the data to
  be received, a human-readable name, and a destination
  to write the data to. Upon validation a UUID is
  generated

  # Examples

  iex> Accept.new(
  ...>                 version: 1,
  ...>                 dataset_id: "456-789",
  ...>                 subset_id: "456-789:2020-01-28",
  ...>                 destination: "gather-456-789-123-456",
  ...>                 connection: %Accept.SampleProtocol{port: 5678, key: "foobar", batch: 1_000}
  ...>               )
  {:ok,
    %Accept{
                 version: 1,
                 id: "123-456",
                 dataset_id: "456-789",
                 subset_id: "456-789:2020-01-28",
                 destination: "gather-456-789-123-456",
                 connection: %Accept.SampleProtocol{port: 5678, key: "foobar", batch: 1_000}
               }
  }
  """
  use Definition, schema: Accept.V1

  @type uuid :: String.t()

  @type t :: %__MODULE__{
          version: integer,
          id: uuid,
          dataset_id: String.t(),
          subset_id: String.t(),
          destination: Destination.t(),
          connection: Accept.Connection.t()
        }

  defstruct version: 1,
            id: nil,
            dataset_id: nil,
            subset_id: nil,
            destination: nil,
            connection: nil

  def on_new(ac) do
    id = UUID.uuid4()

    %{ac | id: id}
    |> Ok.ok()
  end
end

defmodule Accept.V1 do
  @moduledoc false
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      destination: impl_of(Destination),
      connection: is_accept()
    })
  end

  defp is_accept() do
    spec(fn
      %m{} -> m |> to_string() |> String.contains?("Accept")
      _ -> false
    end)
  end
end
