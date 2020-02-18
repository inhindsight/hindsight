defmodule Transform.DeleteField do
  use Definition, schema: Transform.DeleteField.V1

  @type t :: %__MODULE__{
          name: String.t() | [String.t()]
        }

  defstruct [:name]

  import Dictionary.Access, only: [to_access_path: 1]

  defimpl Transform.Step, for: __MODULE__ do
    def transform_dictionary(%{name: name}, dictionary) do
      name_path = to_access_path(name)
      {_, new_dictionary} = pop_in(dictionary, name_path)
      Ok.ok(new_dictionary)
    end

    def create_function(%{name: name}, _dictionary) do
      name_path = to_access_path(name)

      fn value ->
        {_, new_value} = pop_in(value, name_path)
        Ok.ok(new_value)
      end
      |> Ok.ok()
    end
  end
end

defmodule Transform.DeleteField.V1 do
  use Definition.Schema

  def s do
    schema(%Transform.DeleteField{
      name: access_path()
    })
  end
end
