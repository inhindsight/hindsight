defmodule Dictionary.Access do
  def key(key, default \\ nil) do
    &access_fun(key, default, &1, &2, &3)
  end

  defp access_fun(key, default, :get, %module{} = data, next) do
    case module.fetch(data, key) do
      {:ok, value} -> next.(value)
      :error -> next.(default)
    end
  end

  defp access_fun(key, default, :get, list, next) when is_list(list) do
    Enum.map(list, &access_fun(key, default, :get, &1, next))
  end

  defp access_fun(key, default, :get, data, next) do
    next.(Map.get(data, key, default))
  end

  defp access_fun(key, _default, :get_and_update, %module{} = data, next) do
    module.get_and_update(data, key, next)
  end

  defp access_fun(key, default, :get_and_update, list, next) when is_list(list) do
    {gets, updates} =
      Enum.map(list, &access_fun(key, default, :get_and_update, &1, next))
      |> Enum.reduce({[], []}, fn {get, update}, {get_acc, update_acc} ->
        {[get | get_acc], [update | update_acc]}
      end)

    {Enum.reverse(gets), Enum.reverse(updates)}
  end

  defp access_fun(key, default, :get_and_update, data, next) do
    value = Map.get(data, key, default)

    case next.(value) do
      {get, update} -> {get, Map.put(data, key, update)}
      :pop -> {value, Map.delete(data, key)}
    end
  end
end
