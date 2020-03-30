defmodule Source.Context do
  use Definition, schema: Source.Context.V1

  @type t :: %__MODULE__{
          dictionary: Dictionary.t(),
          handler: Source.Handler.impl(),
          app_name: atom | binary,
          dataset_id: String.t(),
          subset_id: String.t(),
          decode_json: boolean,
          assigns: term
        }

  defstruct dictionary: nil,
            handler: nil,
            app_name: nil,
            dataset_id: nil,
            subset_id: nil,
            decode_json: true,
            assigns: nil
end

defmodule Source.Context.V1 do
  use Definition.Schema

  def s do
    schema(%Source.Context{
      dictionary: of_struct(Dictionary.Impl),
      handler: spec(is_atom()),
      app_name: spec(is_atom() or is_binary()),
      dataset_id: required_string(),
      subset_id: required_string(),
      decode_json: spec(is_boolean())
    })
  end
end
