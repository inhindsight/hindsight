defmodule Persist.Compactor do
  @callback compact(Load.Persist.t()) :: :ok | {:error, term}
end

defmodule Persist.Compactor.Presto do
  @behaviour Persist.Compactor
  use Properties, otp_app: :service_persist

  getter(:prestige, required: true)

  def compact(%Load.Persist{} = persist) do
    compact_table = "#{persist.destination}_compact"
    session = Prestige.new_session(prestige())

    with :ok <- create_table(session, persist.destination, compact_table),
         {:ok, _} <- drop_table(session, persist.destination),
         {:ok, _} <- rename_table(session, compact_table, persist.destination) do
      :ok
    end
  end

  defp create_table(session, from, to) do
    create_task =
      Task.async(fn ->
        Prestige.execute(session, "CREATE TABLE #{to} AS SELECT * FROM #{from}")
        |> get_count()
      end)

    query_task =
      Task.async(fn ->
        Prestige.execute(session, "SELECT count(1) FROM #{from}")
        |> get_count()
      end)

    with {:ok, original_count} <- Task.await(create_task, :infinity),
           {:ok, new_count} <- Task.await(query_task, :infinity),
         {:valid?, false} <- {:valid?, original_count == new_count} do
      {:error,
       "Failed '#{from}' compaction: New count (#{new_count}) did not match original count (#{
         original_count
       })"}
    else
      {:valid?, true} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_count({:ok, %{rows: [[count]]}}), do: {:ok, count}
  defp get_count({:ok, result}), do: {:error, "result does not contain count: #{inspect(result)}"}
  defp get_count(error), do: error

  defp drop_table(session, table) do
    Prestige.execute(session, "DROP TABLE #{table}")
  end

  defp rename_table(session, from, to) do
    Prestige.execute(session, "ALTER TABLE #{from} RENAME TO #{to}")
  end
end
