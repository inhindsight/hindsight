defmodule Dataset.Owner.V1 do
  @moduledoc """
  Defines the dataset owner implementation of the
  `Definition.Schema` behaviour and the owner entity
  `s/0` function.

  Returns a valid Norm schema representing a dataset
  owner for validation and defaults the current
  struct version.
  """
  use Definition.Schema

  @impl true
  def s do
    schema(%Dataset.Owner{
      version: version(1),
      id: id(),
      name: required_string(),
      description: string(),
      url: string(),
      image: string(),
      contact:
        schema(%{
          name: required_string(),
          email: spec(email?())
        })
    })
  end
end
