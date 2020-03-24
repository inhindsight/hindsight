defmodule Kafka.Topic.Source do
  use GenServer
  use Annotated.Retry
  require Logger

  def start_link(t, init_opts) do
    with {:ok, pid} <- GenServer.start_link(__MODULE__, {t, init_opts}) do
      %{t | pid: pid}
      |> Ok.ok()
    end
  end

  def stop(_t) do
    :ok
  end

  def delete(_t) do
    :ok
  end

  @impl GenServer
  def init({t, init_opts}) do
    Process.flag(:trap_exit, true)

    state = %{
      t: t,
      dictionary: Keyword.fetch!(init_opts, :dictionary),
      source_handler: Keyword.fetch!(init_opts, :handler),
      app_name: Keyword.fetch!(init_opts, :app_name),
      dataset_id: Keyword.fetch!(init_opts, :dataset_id),
      subset_id: Keyword.fetch!(init_opts, :subset_id)
    }

    {:ok, state, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, state) do
    ensure_topic(state.t)

    {:ok, elsa_pid} =
      Elsa.Supervisor.start_link(
        endpoints: state.t.endpoints,
        connection: :"connection_#{state.app_name}_#{state.t.topic}",
        group_consumer: [
          group: "group-#{state.app_name}-#{state.t.topic}",
          topics: [state.t.topic],
          handler: Kafka.Topic.Source.Handler,
          handler_init_args: state.source_handler,
          config: [
            begin_offset: :earliest,
            offset_reset_policy: :reset_to_earliest,
            prefetch_count: 0,
            prefetch_bytes: 2_097_152
          ]
        ]
      )

    {:noreply, Map.put(state, :elsa_pid, elsa_pid)}
  end

  @impl GenServer
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl GenServer
  def terminate(reason, %{elsa_pid: pid}) do
    Process.exit(pid, reason)
    reason
  end

  def terminate(reason, _) do
    reason
  end

  @retry with: constant_backoff(500) |> take(10)
  defp ensure_topic(t) do
    unless Elsa.topic?(t.endpoints, t.topic) do
      Elsa.create_topic(t.endpoints, t.topic, partitions: t.partitions)
    end
  end
end
