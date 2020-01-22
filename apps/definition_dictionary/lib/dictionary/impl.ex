defmodule Dictionary.Impl do
  @type t :: %__MODULE__{
          by_name: map,
          ordered: list,
          size: integer
        }

  @type field :: term

  defstruct by_name: %{},
            ordered: [],
            size: 0

  @spec from_list(list) :: t
  def from_list(list) do
    Enum.into(list, %__MODULE__{})
  end

  @spec get_field(t, String.t()) :: field
  def get_field(%__MODULE__{by_name: by_name}, name) do
    case Map.get(by_name, name) do
      {_, field} -> field
      result -> result
    end
  end

  @spec update_field(t, String.t(), field | (field -> field)) :: t
  def update_field(%__MODULE__{} = dictionary, name, update_function)
      when is_function(update_function, 1) do
    new_field =
      get_field(dictionary, name)
      |> update_function.()

    update_field(dictionary, name, new_field)
  end

  def update_field(%__MODULE__{} = dictionary, name, new_field) do
    {index, _} = Map.get(dictionary.by_name, name)
    new_name = new_field.name

    Map.update!(dictionary, :by_name, fn bn ->
      Map.delete(bn, name)
      |> Map.put(new_name, {index, new_field})
    end)
    |> Map.update!(:ordered, fn list ->
      List.replace_at(list, index, new_field)
    end)
  end

  defimpl Collectable, for: __MODULE__ do
    def into(original) do
      collector_fun = fn
        dictionary, {:cont, elem} ->
          Map.update!(dictionary, :by_name, fn map ->
            Map.put(map, elem.name, {dictionary.size, elem})
          end)
          |> Map.update!(:ordered, fn list -> [elem | list] end)
          |> Map.update!(:size, fn size -> size + 1 end)

        dictionary, :done ->
          Map.update!(dictionary, :ordered, fn list -> Enum.reverse(list) end)

        _dictionary, :halt ->
          :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Enumerable, for: __MODULE__ do
    def reduce(%{ordered: ordered}, acc, fun) do
      Enumerable.reduce(ordered, acc, fun)
    end

    def count(%{ordered: ordered}) do
      Enumerable.count(ordered)
    end

    def member?(%{ordered: ordered}, element) do
      Enumerable.member?(ordered, element)
    end

    def slice(%{ordered: ordered}) do
      Enumerable.slice(ordered)
    end
  end
end
