defmodule Definition.Schema.Owner.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Definition.Owner{
      version: spec(fn v -> v == 1 end),
      id: string(),
      name: string(),
      title: string(),
      description: spec(is_binary()),
      url: spec(is_binary()),
      image: spec(is_binary()),
      contact: schema(%{
        name: string(),
        email: spec(email?())
      })
    })
  end

  defp string, do: spec(is_binary() and not_empty?())
end
