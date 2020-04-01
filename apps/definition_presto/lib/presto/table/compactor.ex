defmodule Presto.Table.Compactor do
  use Properties, otp_app: :definition_presto

  @callback compact(Load.t()) :: :ok | {:error, term}

  getter(:impl, default: Presto.Table.Compactor.Presto)

  def compact(load) do
    impl().compact(load)
  end
end

defmodule Presto.Table.Compactor.Presto do
  @behaviour Presto.Table.Compactor
  use Properties, otp_app: :definition_presto

  getter(:catalog, required: true)
  getter(:user, required: true)

  @impl true
  def compact(table) do
    compact_table = "#{table.name}_compact"
    session = new_session(table)

    with {:ok, _} <- drop_table(session, compact_table),
         :ok <- create_table(session, table.name, compact_table),
         {:ok, _} <- drop_table(session, table.name),
         {:ok, _} <- rename_table(session, compact_table, table.name) do
      :ok
    else
      {:error, reason} ->
        drop_table(session, compact_table)
        {:error, reason}
    end
  end

  defp create_table(session, from, to) do
    create_task =
      Task.async(fn ->
        Presto.Table.Manager.create_from(session, to, from, format: :orc, with_data: true)
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
    Prestige.execute(session, "DROP TABLE IF EXISTS #{table}")
  end

  defp rename_table(session, from, to) do
    Prestige.execute(session, "ALTER TABLE #{from} RENAME TO #{to}")
  end

  defp new_session(table) do
    Prestige.new_session(
      url: table.url,
      catalog: catalog(),
      schema: table.schema,
      user: user()
    )
  end
end
