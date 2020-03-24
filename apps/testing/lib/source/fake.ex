defmodule Source.Fake do
  @derive Jason.Encoder
  defstruct [:pid, :agent]

  def new() do
    {:ok, agent} = Agent.start_link(fn -> %{} end)

    %__MODULE__{
      pid: self(),
      agent: agent
    }
  end

  def inject_messages(t, messages) do
    state = Agent.get(t.agent, & &1)

    Enum.reduce(messages, [], fn msg, acc ->
      case state.handler.handle_message(msg) do
        {:ok, new_msg} -> [new_msg | acc]
        {:error, _reason} -> acc
      end
    end)
    |> Enum.reverse()
    |> state.handler.handle_batch()
  end

  defimpl Source do
    def start_link(t, opts) do
      Agent.update(t.agent, fn s -> Map.new(opts) end)
      send(t.pid, {:source_start_link, t, opts})
      {:ok, t}
    end

    def stop(t) do
      send(t.pid, {:source_stop, t})
      :ok
    end

    def delete(t) do
      send(t.pid, {:source_delete, t})
      :ok
    end
  end
end
