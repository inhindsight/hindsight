defmodule Dictionary.Type.Integer do
  use Definition, schema: Dictionary.Type.Integer.V1
  use Dictionary.JsonEncoder

  defstruct version: 1,
            name: nil,
            description: ""
end

defmodule Dictionary.Type.Integer.V1 do
  use Definition.Schema

  def s do
    schema(%Dictionary.Type.Integer{
      version: spec(fn v -> v == 1 end),
      name: spec(is_binary() and not_empty?()),
      description: spec(is_binary())
    })
  end
end
