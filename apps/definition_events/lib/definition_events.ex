defmodule Definition.Events do
  @events [
    {"extract:start", Extract},
    {"extract:end", Extract},
    {"load:stream:start", Load.Broadcast},
    {"load:stream:end", Load.Broadcast}
  ]

  Enum.map(@events, fn {type, struct_module} ->
    fun_name = type |> String.replace(":", "_") |> String.to_atom()
    defmacro unquote(fun_name)(), do: unquote(type)

    fun_name = :"send_#{String.replace(type, ":", "_")}"

    def unquote(fun_name)(instance, author, %unquote(struct_module){} = data) do
      Brook.Event.send(instance, unquote(type), author, data)
    end

    def unquote(fun_name)(_instance, _author, data) do
      raise "Invalid event being created: type = #{unquote(type)}, data = #{inspect(data)}"
    end
  end)
end
