defmodule Dataset.Owner do
  @moduledoc """
  Defines the structure of a dataset owner within Hindsight.

  Owners track the metadata attached to one or more datasets
  within the system in a single record, including the name,
  a description, and branding and contact information.

  # Examples

    iex> Dataset.Owner.new(
    ...>                    version: 1,
    ...>                    id: "123-456",
    ...>                    name: "SteveCo",
    ...>                    description: "SteveCo fixes your data!",
    ...>                    url: "steve.co",
    ...>                    image: "https://steve.co/assets/branding/logo.png",
    ...>                    contact: %{
    ...>                      name: "Steve Stevenson",
    ...>                      email: "me@steve.co"
    ...>                    }
    ...>                  )
    {:ok,
      %Dataset.Owner{
                      version: 1,
                      id: "123-456",
                      name: "SteveCo",
                      description: "SteveCo fixes your data!",
                      url: "steve.co",
                      image: "https://steve.co/assets/branding/logo.png",
                      contact: %{
                        name: "Steve Stevenson",
                        email: "me@steve.co"
                      }
                    }
    }
  """
  use Definition, schema: Dataset.Owner.V1

  defstruct version: nil,
            id: nil,
            name: nil,
            description: "",
            url: "",
            image: "",
            contact: %{
              name: nil,
              email: nil
            }
end
