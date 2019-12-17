defmodule Dataset.Schema.Owner.V1 do
  @behaviour Dataset.Schema

  import Norm
  import Dataset.Schema.Validation

  @impl Dataset.Schema
  def s do
    schema(%Dataset.Owner{
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
