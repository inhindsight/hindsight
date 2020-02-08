defmodule Accept.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Accept{
      version: version(1),
      id: id(),
      dataset_id: id(),
      subset_id: required_string(),
      destination: required_string(),
      connection: is_accept()
    })
  end

  defp is_accept() do
    spec(fn
      %m{} -> m |> to_string |> String.contains?("Accept")
      _ -> false
    end)
  end
end
