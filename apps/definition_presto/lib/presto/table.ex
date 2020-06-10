defmodule Presto.Table do
  @moduledoc """
  Defines a PrestoDB table and makes it a `Destination.t()` impl.

  ## Configuration

  * `url` - Required. PrestoDB location.
  * `name` - Required. Table name.
  * `schema` - Optional database schema. Defaults to `"default"`.
  * `pid` - Optional. Tracks writer processes for specific table instance.
  """
  use Definition, schema: Presto.Table.V1
  use JsonSerde, alias: "presto_table"

  @type t :: %__MODULE__{
          version: integer,
          url: String.t(),
          schema: String.t(),
          name: String.t(),
          pid: pid
        }

  defstruct version: 1,
            url: nil,
            schema: "default",
            name: nil,
            pid: nil

  @spec compact(t) :: :ok | {:error, term}
  defdelegate compact(table), to: Presto.Table.Compactor

  defimpl Destination do
    defdelegate start_link(t, context), to: Presto.Table.Destination
    defdelegate write(t, server, messages), to: Presto.Table.Destination
    defdelegate stop(t, server), to: Presto.Table.Destination
    defdelegate delete(t), to: Presto.Table.Destination
  end
end

defmodule Presto.Table.V1 do
  @moduledoc false
  use Definition.Schema

  def s do
    schema(%Presto.Table{
      version: version(1),
      url: required_string(),
      schema: required_string(),
      name: required_string()
    })
  end
end
