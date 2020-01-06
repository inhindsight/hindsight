defmodule Writer.Presto do
  @behaviour Writer
  use GenServer

  defmodule State do
    defstruct [:session, :table, :table_schema]
  end

  @impl Writer
  def start_link(args) do
    server_opts = [name: Keyword.get(args, :name, nil)]
    GenServer.start_link(__MODULE__, args, server_opts)
  end

  @impl Writer
  def write(server, messages, opts \\ []) do
    GenServer.call(server, {:write, messages, opts})
  end

  @impl GenServer
  def init(args) do
    session =
      Prestige.new_session(
        url: Keyword.fetch!(args, :url),
        user: Keyword.fetch!(args, :user),
        catalog: Keyword.get(args, :catalog, nil),
        schema: Keyword.get(args, :schema, nil)
      )

    state = %State{
      session: session,
      table: Keyword.fetch!(args, :table),
      table_schema: Keyword.fetch!(args, :table_schema)
    }

    create_table(state)

    Ok.ok(state)
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    columns =
      state.table_schema
      |> Enum.map(fn {name, _} -> name end)
      |> Enum.join(",")

    values = format_rows(state.table_schema, messages)
    insert_stmt = "INSERT INTO #{state.table}(#{columns}) VALUES #{values}"

    Prestige.execute!(state.session, insert_stmt)
    reply(:ok, state)
  end

  defp create_table(state) do
    columns =
      state.table_schema
      |> Enum.map(fn {name, type} -> "#{name} #{type}" end)
      |> Enum.join(",")

    create_table = "CREATE TABLE IF NOT EXISTS #{state.table} (#{columns})"
    Prestige.execute!(state.session, create_table)
  end

  defp format_rows(schema, rows) do
    rows
    |> Enum.map(&format_row(schema, &1))
    |> Enum.map(fn row -> "(#{row})" end)
    |> Enum.join(",")
  end

  defp format_row(schema, row) do
    schema
    |> Enum.map(fn {column, _} -> Map.get(row, column) end)
    |> Enum.map(fn value -> format(value) end)
    |> Enum.join(",")
  end

  defp format([{_a, _b} | _t] = values) do
    value_string =
      values
      |> Enum.map(fn {_name, value} -> value end)
      |> Enum.map(&format/1)
      |> Enum.join(",")

    "row(#{value_string})"
  end

  defp format(values) when is_list(values) do
    value_string =
      Enum.map(values, &format/1)
      |> Enum.join(",")

    "array[#{value_string}]"
  end

  defp format(value) when is_binary(value), do: "'#{value}'"
  defp format(value), do: value

  defp reply(message, state), do: {:reply, message, state}
end
