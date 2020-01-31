defmodule Acquire.Query do
  # TODO
  @moduledoc false

  use Definition, schema: Acquire.Query.V1

  @type t :: %__MODULE__{
          table: String.t(),
          fields: [String.t()],
          limit: nil,
          where: nil
        }

  defstruct table: nil,
            fields: ["*"],
            limit: nil,
            where: nil
end

defmodule Acquire.Query.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query{
      table: spec(table_name?()),
      fields: coll_of(required_string()),
      limit: spec(is_nil() or pos_integer?())
    })
  end
end
