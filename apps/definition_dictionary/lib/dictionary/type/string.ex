defmodule Dictionary.Type.String do
  use Definition, schema: Dictionary.Type.String.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: ""
end

defmodule Dictionary.Type.String.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.String{
      version: spec(fn v -> v == 1 end),
      name: spec(is_binary() and not_empty?()),
      description: spec(is_binary())
    })
  end
end
