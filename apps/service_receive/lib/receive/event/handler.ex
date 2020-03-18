defmodule Receive.Event.Handler do
  use Brook.Event.Handler
  use Properties, otp_app: :service_receive
  require Logger

  alias Receive.SocketManager
  import Events, only: [accept_start: 0, accept_end: 0, dataset_delete: 0]

  getter(:endpoints, required: true)

  def handle_event(%Brook.Event{type: accept_start(), data: %Accept{} = accept}) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_start()}: #{inspect(accept)}" end)

    Receive.Accept.Supervisor.start_child({SocketManager, accept: accept})
    Receive.Accept.Store.persist(accept)
    :ok
  end

  def handle_event(%Brook.Event{
        type: accept_end(),
        data: %Accept{dataset_id: id, subset_id: sid} = accept
      }) do
    Logger.debug(fn -> "#{__MODULE__}: Received event #{accept_end()}: #{inspect(accept)}" end)
    Receive.Accept.Store.mark_done(dataset_id: id, subset_id: sid)

    terminate_manager(accept)

    :ok
  end

  def handle_event(%Brook.Event{type: dataset_delete(), data: %Delete{} = delete}) do
    Logger.debug(fn ->
      "#{__MODULE__}: Received event #{dataset_delete()}: #{inspect(delete)}"
    end)

    case Receive.Accept.Store.get!(delete.dataset_id, delete.subset_id) do
      nil ->
        Logger.debug("No existing state to delete")
        nil

      accept ->
        terminate_manager(accept)

        if Elsa.topic?(endpoints(), accept.destination),
          do: Elsa.delete_topic(endpoints(), accept.destination)

        Logger.debug("Deleted Supervisor and Topic")
    end

    Receive.Accept.Store.delete(delete.dataset_id, delete.subset_id)
    :ok
  end

  defp terminate_manager(%Accept{} = accept) do
    case Receive.Accept.Registry.whereis(:"#{accept.destination}_manager") do
      :undefined ->
        Logger.debug("No manager to delete for #{inspect(accept)}")

      pid ->
        Receive.Accept.Supervisor.terminate_child(pid)
    end
  end
end
