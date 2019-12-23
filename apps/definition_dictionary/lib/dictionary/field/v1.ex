defmodule Dictionary.Field.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Dictionary.Field{
      version: spec(fn v -> v == 1 end),
      name: spec(is_binary() and not_empty?()),
      type: spec(is_binary() and not_empty?()),
      description: spec(is_binary()),
      fields: spec(is_list())
    })
  end
end
