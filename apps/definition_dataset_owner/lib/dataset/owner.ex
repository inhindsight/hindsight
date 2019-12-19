defmodule Dataset.Owner do
  use Definition, schema: Dataset.Owner.V1

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
