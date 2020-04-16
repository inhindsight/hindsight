defmodule Initializer do
  @moduledoc """
  Behaviour for reconnecting services to pre-existing event state.
  """

  @callback on_start(state) :: {:ok, state} | {:error, term} when state: map

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    supervisor = Keyword.fetch!(opts, :supervisor)

    quote location: :keep do
      use GenServer
      use Annotated.Retry

      @behaviour Initializer

      @dialyzer [
        {:nowarn_function, handle_info: 2},
        {:no_match, init: 1}
      ]

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg, name: unquote(name))
      end

      def init(init_arg) do
        supervisor_ref = setup_monitor()

        state =
          Map.new(init_arg)
          |> Map.put(:supervisor_ref, supervisor_ref)

        {:ok, state, {:continue, :init}}
      end

      def handle_continue(:init, state) do
        case do_on_start(state) do
          {:ok, new_state} -> {:noreply, new_state}
          {:error, reason} -> {:stop, reason}
        end
      end

      def handle_info({:DOWN, supervisor_ref, _, _, _}, %{supervisor_ref: supervisor_ref} = state) do
        case do_wait_for_supervisor(supervisor_ref) do
          {:ok, _} ->
            supervisor_ref = setup_monitor()
            state = Map.put(state, :supervisor_ref, supervisor_ref)

            case on_start(state) do
              {:ok, new_state} -> {:noreply, state}
              {:error, reason} -> {:stop, reason, state}
            end

          _ ->
            {:stop, "Supervisor not available", state}
        end
      end

      @retry with: constant_backoff(100) |> take(10)
      defp do_wait_for_supervisor(supervisor) do
        sup_pid = Process.whereis(unquote(supervisor))

        case sup_pid do
          nil -> {:error, "Failed to get supervisor"}
          _ -> {:ok, sup_pid}
        end
      end

      @retry with: constant_backoff(100) |> take(10)
      defp do_on_start(state) do
        with {:ok, new_state} <- on_start(state), do: {:ok, new_state}
      end

      defp setup_monitor() do
        Process.whereis(unquote(supervisor))
        |> Process.monitor()
      end
    end
  end
end
