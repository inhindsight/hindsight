defmodule Presto.Table do
  use Definition, schema: Presto.Table.V1

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
  defdelegate compact(table), to: Presto.Table.Compactor.Presto

  defimpl Destination do
    defdelegate start_link(t, context), to: Presto.Table.Destination
    defdelegate write(t, messages), to: Presto.Table.Destination
    defdelegate stop(t), to: Presto.Table.Destination
    defdelegate delete(t), to: Presto.Table.Destination
  end
end

defmodule Presto.Table.V1 do
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
