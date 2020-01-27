defmodule Dictionary.Type.Map do
  use Definition, schema: Dictionary.Type.Map.V1
  use Dictionary.JsonEncoder
  @behaviour Access

  @type t :: %__MODULE__{
          version: integer,
          name: String.t(),
          description: String.t(),
          dictionary: Dictionary.t()
        }

  defstruct version: 1,
            name: nil,
            description: "",
            dictionary: Dictionary.from_list([])

  @impl Definition
  def on_new(%{dictionary: list} = map) when is_list(list) do
    with {:ok, decoded_dictionary} <- Dictionary.decode(list),
         dictionary <- Dictionary.from_list(decoded_dictionary) do
      Map.put(map, :dictionary, dictionary)
      |> Ok.ok()
    end
  end

  def on_new(map) do
    Ok.ok(map)
  end

  @impl Access
  def fetch(%{dictionary: dictionary}, key) do
    Dictionary.Impl.fetch(dictionary, key)
  end

  @impl Access
  def get_and_update(map, key, function) do
    {return, new_dictionary} = Dictionary.Impl.get_and_update(map.dictionary, key, function)
    {return, Map.put(map, :dictionary, new_dictionary)}
  end

  @impl Access
  def pop(map, key) do
    field = Dictionary.get_field(map.dictionary, key)
    new_dict = Dictionary.delete_field(map.dictionary, key)
    {field, Map.put(map, :dictionary, new_dict)}
  end

  defimpl Dictionary.Type.Normalizer, for: __MODULE__ do
    def normalize(%{dictionary: dictionary}, map) do
      Dictionary.normalize(dictionary, map)
    end
  end
end

defmodule Dictionary.Type.Map.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Dictionary.Type.Map{
      version: version(1),
      name: required_string(),
      description: string(),
      dictionary: of_struct(Dictionary.Impl)
    })
  end
end
