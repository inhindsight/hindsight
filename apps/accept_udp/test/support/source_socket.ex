defmodule SourceSocket do
  use GenServer

  def hit_me(), do: GenServer.cast(__MODULE__, :hit_me)

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_udp.open(port - 1)

    :timer.send_interval(100, :push_message)

    {:ok, %{socket: socket, port: port}}
  end

  def handle_cast(:hit_me, %{socket: socket, port: port} = state) do
    message = generate_payload()
    :gen_udp.send(socket, {127, 0, 0, 1}, port, message)

    {:noreply, state}
  end

  def handle_info(:push_message, %{socket: socket, port: port} = state) do
    message = generate_payload()
    :gen_udp.send(socket, {127, 0, 0, 1}, port, message)

    {:noreply, state}
  end

  defp generate_payload() do
    length = :crypto.rand_uniform(0, 25)
    payload = :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)

    "{\"payload\":\"#{payload}\"}"
  end
end
