defmodule Dlq.Application do
  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Dlq.Supervisor]
    Supervisor.start_link(server(), opts)
  end

  defp server() do
    case Application.get_env(:dlq, Dlq.Server) do
      nil -> []
      _ -> [Dlq.Server]
    end
  end
end
