defmodule Receive.Event.Handler do
  @moduledoc """
  Callbacks for handling events from `Brook`.
  """
  use Brook.Event.Handler
  use Properties, otp_app: :service_receive
  require Logger

  alias Receive.SocketManager
  alias Receive.ViewState
  import Events, only: [accept_start: 0, accept_end: 0, dataset_delete: 0]
  import Definition, only: [identifier: 1]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{type: accept_start(), data: %Accept{} = accept}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_start()}: #{inspect(accept)}" end)

    Receive.Accept.Supervisor.start_child({SocketManager, accept: accept})

    key = identifier(accept)
    ViewState.Accepts.persist(key, accept)
    ViewState.Destinations.persist(key, accept.destination)

    :ok
  end

  def handle_event(%Brook.Event{type: accept_end(), data: %Accept{} = accept}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_end()}: #{inspect(accept)}" end)
    terminate_manager(accept)

    identifier(accept)
    |> ViewState.Accepts.delete()

    :ok
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    key = identifier(delete)

    case ViewState.Accepts.get(key) do
      {:ok, nil} ->
        Logger.debug(fn -> "No existing state to delete for #{key}" end)
        delete_destination(key)
        :discard

      {:ok, accept} ->
        terminate_manager(accept)
        delete_destination(key)
        ViewState.Accepts.delete(key)

      {:error, reason} ->
        raise reason
    end
  end

  defp delete_destination(key) do
    case ViewState.Destinations.get(key) do
      {:ok, nil} ->
        Logger.debug(fn -> "No destination data to delete for #{key}" end)

      {:ok, destination} ->
        Destination.delete(destination)
        ViewState.Destinations.delete(key)
        Logger.debug(fn -> "Deleted destination for #{key}" end)
    end
  end

  defp terminate_manager(%Accept{} = accept) do
    case Receive.Accept.Registry.whereis(:"#{identifier(accept)}_manager") do
      :undefined ->
        Logger.debug("No manager to delete for #{inspect(accept)}")

      pid ->
        Receive.Accept.Supervisor.terminate_child(pid)
        Logger.debug(fn -> "Deleted supervisor for #{identifier(accept)}" end)
    end
  end
end
