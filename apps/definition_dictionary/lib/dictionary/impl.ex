defmodule Dictionary.Impl do
  @behaviour Access

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
    {index, new_ordered} =
      case Map.get(dictionary.by_name, name) do
        {index, _} ->
          {index, List.replace_at(dictionary.ordered, index, new_field)}

        nil ->
          index = length(dictionary.ordered)
          {index, List.insert_at(dictionary.ordered, index, new_field)}
      end

    new_name = new_field.name

    Map.update!(dictionary, :by_name, fn bn ->
      Map.delete(bn, name)
      |> Map.put(new_name, {index, new_field})
    end)
    |> Map.put(:ordered, new_ordered)
  end

  @spec delete_field(t, String.t()) :: t
  def delete_field(%__MODULE__{} = dictionary, name) do
    case Map.get(dictionary.by_name, name) do
      {index, _field} ->
        dictionary.ordered
        |> List.delete_at(index)
        |> from_list()

      _ ->
        dictionary
    end
  end

  @impl Access
  def fetch(term, key) do
    case get_field(term, key) do
      nil -> :error
      value -> Ok.ok(value)
    end
  end

  @impl Access
  def get_and_update(data, key, function) do
    field = get_field(data, key)

    case function.(field) do
      {get_value, update_value} ->
        {get_value, update_field(data, key, update_value)}

      :pop ->
        {field, delete_field(data, key)}
    end
  end

  @impl Access
  def pop(data, key) do
    field = get_field(data, key)
    {field, delete_field(data, key)}
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

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{ordered: ordered}, opts) do
      Jason.Encode.list(ordered, opts)
    end
  end

  defimpl Brook.Serializer.Protocol, for: __MODULE__ do
    def serialize(%{ordered: ordered}) do
      Brook.Serializer.Protocol.List.serialize(ordered)
    end
  end
end
