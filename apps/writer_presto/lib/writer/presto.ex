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

    case create_table(state) do
      {:ok, _} -> Ok.ok(state)
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl GenServer
  def handle_call({:write, messages, _opts}, _from, state) do
    columns =
      state.table_schema
      |> Enum.map(fn {name, _} -> name end)
      |> Enum.join(",")

    values = format_rows(messages)
    insert_stmt = "INSERT INTO #{state.table}(#{columns}) VALUES #{values}"

    case Prestige.execute(state.session, insert_stmt) do
      {:ok, _} -> reply(:ok, state)
      {:error, reason} -> reply({:error, reason}, state)
    end
  end

  defp create_table(state) do
    columns =
      state.table_schema
      |> Enum.map(fn {name, type} -> "#{name} #{type}" end)
      |> Enum.join(",")

    create_table = "CREATE TABLE IF NOT EXISTS #{state.table} (#{columns})"
    Prestige.execute(state.session, create_table)
  end

  defp format_rows(rows) do
    rows
    |> Enum.map(&format_row/1)
    |> Enum.map(fn row -> "(#{row})" end)
    |> Enum.join(",")
  end

  defp format_row(row) when is_tuple(row) do
    row
    |> Tuple.to_list()
    |> Enum.map(&format/1)
    |> Enum.join(",")
  end

  defp format(value) when is_tuple(value) do
    value_string =
      value
      |> Tuple.to_list()
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
