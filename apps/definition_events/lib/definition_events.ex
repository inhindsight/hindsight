defmodule Definition.Events do
  @events [
    {"extract:start", Extract},
    {"extract:end", Extract},
    {"load:broadcast:start", Load.Broadcast},
    {"load:broadcast:end", Load.Broadcast},
    {"load:persist:start", Load.Persist},
    {"load:persist:end", Load.Persist},
    {"schedule:start", Schedule},
    {"schedule:end", Schedule},
    {"transform:define", Transform}
  ]

  Enum.map(@events, fn {type, struct_module} ->
    fun_name = type |> String.replace(":", "_") |> String.to_atom()
    defmacro unquote(fun_name)(), do: unquote(type)

    send_fun_name = :"send_#{String.replace(type, ":", "_")}"

    def unquote(send_fun_name)(instance, author, %unquote(struct_module){} = data) do
      Brook.Event.send(instance, unquote(type), author, data)
    end

    def unquote(send_fun_name)(_instance, _author, data) do
      raise "Invalid event being created: type = #{unquote(type)}, data = #{inspect(data)}"
    end
  end)

  Enum.map(@events, fn {type, struct_module} ->
    parts = String.split(type, ":")
    action = List.last(parts)

    def get_event_type(unquote(action), %unquote(struct_module){}) do
      unquote(type)
    end
  end)

  def get_event_type(action, struct) do
    raise "Unknown event type: action: #{inspect(action)}, struct: #{inspect(struct)}"
  end
end
