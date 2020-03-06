defmodule Dictionary.Type.List do
  use Definition, schema: Dictionary.Type.List.V1
  use Dictionary.JsonEncoder
  @behaviour Access

  @type t :: %__MODULE__{
          version: integer,
          name: String.t(),
          description: String.t(),
          item_type: module
        }

  defstruct version: 1,
            name: nil,
            description: "",
            item_type: nil

  @impl Definition
  def on_new(%{item_type: %{"type" => type} = item_type} = data) do
    with {:ok, module} <- Dictionary.Type.from_string(type),
         {:ok, new_item_type} <- module.new(item_type) do
      Map.put(data, :item_type, new_item_type)
      |> Ok.ok()
    end
  end

  def on_new(data) do
    Ok.ok(data)
  end

  @impl Access
  def fetch(%{item_type: %module{} = item_type}, key) do
    module.fetch(item_type, key)
  end

  @impl Access
  def get_and_update(%{item_type: %module{} = item_type} = list, key, function) do
    {get, update} = module.get_and_update(item_type, key, function)
    {get, %{list | item_type: update}}
  end

  @impl Access
  def pop(%{item_type: %module{} = item_type} = list, key) do
    {value, update} = module.pop(item_type, key)
    {value, %{list | item_type: update}}
  end

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    alias Dictionary.Type.Normalizer

    def normalize(_, nil), do: Ok.ok(nil)

    def normalize(%{item_type: item_type}, list) do
      Ok.transform(list, &Normalizer.normalize(item_type, &1))
      |> Ok.map_if_error(fn reason -> {:invalid_list, reason} end)
    end
  end
end

defmodule Dictionary.Type.List.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Dictionary.Type.List{
      version: version(1),
      name: lowercase_string(),
      description: string(),
      item_type: spec(is_map())
    })
  end
end
