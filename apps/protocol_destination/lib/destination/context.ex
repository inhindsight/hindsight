defmodule Destination.Context do
  use Definition, schema: Destination.Context.V1

  @type t :: %__MODULE__{
          dictionary: Dictionary.t(),
          app_name: String.t() | atom,
          dataset_id: String.t(),
          subset_id: String.t()
        }

  defstruct [:dictionary, :app_name, :dataset_id, :subset_id]
end

defmodule Destination.Context.V1 do
  use Definition.Schema

  def s do
    schema(%Destination.Context{
      dictionary: of_struct(Dictionary.Impl),
      app_name: spec(is_atom() or is_binary()),
      dataset_id: required_string(),
      subset_id: required_string()
    })
  end
end
