defmodule Definition.Owner do
  use Definition, schema: Definition.Schema.Owner.V1

  defstruct version: nil,
            id: nil,
            name: nil,
            title: nil,
            description: "",
            url: "",
            image: "",
            contact: %{
              name: nil,
              email: nil
            }
end
