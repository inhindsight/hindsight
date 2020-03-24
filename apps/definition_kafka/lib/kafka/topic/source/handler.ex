defmodule Kafka.Topic.Source.Handler do
  use Elsa.Consumer.MessageHandler
  use Properties, otp_app: :definition_kafka

  alias Dlq.DeadLetter

  getter(:dlq, default: Dlq)

  def handle_messages(messages, state) do
    messages
    |> Enum.map(fn msg -> %{original: msg, value: msg.value, error: nil, stacktrace: nil} end)
    |> Enum.map(&decode/1)
    |> Enum.map(&handle_message(&1, state.source_handler))
    |> Enum.group_by(fn
      %{error: nil} -> :ok
      _ -> :error
    end)
    |> Enum.each(&handle(&1, state))

    {:ack, state}
  end

  defp handle({:ok, messages}, state) do
    messages
    |> Enum.map(&Map.get(&1, :value))
    |> state.source_handler.handle_batch()
  end

  defp handle({:error, messages}, state) do
    messages
    |> Enum.map(&to_dead_letter(state, &1))
    |> send_to_dlq()
  end

  defp decode(%{value: value} = msg) do
    case Jason.decode(value) do
      {:ok, decoded_value} -> %{msg | value: decoded_value}
      {:error, reason} -> %{msg | error: reason}
    end
  end

  defp handle_message(%{error: nil, value: value} = msg, source_handler) do
    case source_handler.handle_message(value) do
      {:ok, new_value} -> %{msg | value: new_value}
      {:error, reason} -> %{msg | error: reason}
    end
  catch
    _, reason ->
      %{msg | error: reason, stacktrace: __STACKTRACE__}
  end

  defp handle_message(msg, _), do: msg

  defp to_dead_letter(state, msg) do
    DeadLetter.new(
      app_name: to_string(state.app_name),
      dataset_id: state.dataset_id,
      subset_id: state.subset_id,
      original_message: msg.original,
      reason: msg.error,
      stacktrace: msg.stacktrace
    )
  end

  defp send_to_dlq([]), do: :ok
  defp send_to_dlq(msgs), do: dlq().write(msgs)
end
