defmodule Source.Fake do
  @derive Jason.Encoder
  defstruct [:id]

  def new() do
    case :ets.whereis(__MODULE__) do
      :undefined -> :ets.new(__MODULE__, [:named_table, :public])
      _ -> :ok
    end

    id = id()
    :ets.insert(__MODULE__, {id, self(), nil})

    %__MODULE__{
      id: id
    }
  end

  def inject_messages(t, messages) do
    context = :ets.lookup_element(__MODULE__, t.id, 3)

    messages
    |> Enum.map(fn msg ->
      encoded = Jason.encode!(msg)
      %Source.Message{original: encoded, value: encoded}
    end)
    |> Source.Handler.inject_messages(context)
  end

  defp id() do
    Integer.to_string(:rand.uniform(4_294_967_296), 32) <>
      Integer.to_string(:rand.uniform(4_294_967_296), 32)
  end

  defimpl Source do
    def start_link(t, context) do
      :ets.update_element(Source.Fake, t.id, {3, context})
      pid = :ets.lookup_element(Source.Fake, t.id, 2)
      send(pid, {:source_start_link, t, context})
      {:ok, t}
    end

    def stop(t) do
      pid = :ets.lookup_element(Source.Fake, t.id, 2)
      send(pid, {:source_stop, t})
      :ok
    end

    def delete(t) do
      pid = :ets.lookup_element(Source.Fake, t.id, 2)
      send(pid, {:source_delete, t})
      :ok
    end
  end
end
