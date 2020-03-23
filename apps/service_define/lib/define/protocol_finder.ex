defmodule Define.ProtocolFinder do
  def find() do
    paths =
      Application.spec(:extractor)
      |> Keyword.get(:applications)
      |> Enum.map(&:code.lib_dir(&1, :ebin))

    modules = Protocol.extract_impls(Extract.Step, paths)

    Enum.map(modules, &{&1, Code.Typespec.fetch_types(&1) |> elem(1)})
    |> Enum.map(&extract_fields/1)
  end

  @spec get_types(atom()) :: %{required(String.t()) => String.t()}
  def get_types(module) do
    {:ok, [type_spec]} = Code.Typespec.fetch_types(module)

    type_spec
    |> extract_fields()
    |> Enum.map(fn
      {k, v} when is_atom(v) -> {to_string(k), to_string(v)}
      {k, v} -> {to_string(k), v}
    end)
    |> Enum.into(%{})
  end

  def extract_fields([]) do
    []
  end

  def extract_fields({:type, {:t, {:type, _, :map, fields}, _}}) do
    fields
    |> Enum.map(&IO.inspect/1)
    |> Enum.map(&do_line/1)
    |> Enum.reject(fn
      {:__struct__, _} -> true
      {:version, _} -> true
      {name, type} -> false
    end)
  end

  def do_line({:type, _, _, [{_, _, name}, {_, _, [{:atom, 0, String}, {:atom, 0, :t}, []]}]}),
    do: {name, :string}

  def do_line({:type, _, _, [{_, _, name}, {_, _, :list, [{_, _, [{_, _, String}, _, _]}]}]}), do: {name, {"list", "string"}}

  def do_line({:type, _, _, [{_, _, name}, {_, _, :list, [{_, _, type, _}]}]}), do: {name, {"list", to_string(type)}}

  def do_line({:type, _, _, [{_, _, name}, {_, _, type}]}), do: {name, type}

  def do_line({:type, _, _, [{_, _, name}, {_, _, type, _}]}), do: {name, type}
end

# right: [
#          {Extract.Decode.Csv,
#           {:ok,
#            [
#              type: {:t,
#               {:type, 6, :map,
#                [
#                  {:type, 6, :map_field_exact, [{:atom, 0, :__struct__}, {:atom, 0, Extract.Decode.Csv}]},
#                  {:type, 6, :map_field_exact, [{:atom, 0, :headers}, {:type, 8, :list, []}]},
#                  {:type, 6, :map_field_exact, [{:atom, 0, :skip_first_line}, {:type, 9, :boolean, []}]},
#                  {:type, 6, :map_field_exact, [{:atom, 0, :version}, {:type, 7, :integer, []}]}
#                ]}, []}
#            ]}},
#          {Extract.Decode.JsonLines, {:ok, []}},
#          {Extract.Decode.Json, {:ok, []}},
#          {Extract.Decode.Gtfs, {:ok, []}},
#          {Extract.Kafka.Subscribe,
#           {:ok,
#            [
#              type: {:t,
#               {:type, 5, :map,
#                [
#                  {:type, 5, :map_field_exact, [{:atom, 0, :__struct__}, {:atom, 0, Extract.Kafka.Subscribe}]},
#                  {:type, 5, :map_field_exact, [{:atom, 0, :endpoints}, {:remote_type, 0, [{:atom, 0, :elixir}, {:atom, 0, :keyword}, []]}]},
#                  {:type, 5, :map_field_exact, [{:atom, 0, :topic}, {:remote_type, 8, [{:atom, 0, String}, {:atom, 0, :t}, []]}]},
#                  {:type, 5, :map_field_exact, [{:atom, 0, :version}, {:type, 6, :integer, []}]}
#                ]}, []}
#            ]}},
#          {Extract.Http.Get,
#           {:ok,
#            [
#              type: {:t,
#               {:type, 4, :map,
#                [
#                  {:type, 4, :map_field_exact, [{:atom, 0, :__struct__}, {:atom, 0, Extract.Http.Get}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :headers}, {:type, 7, :map, :any}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :url}, {:remote_type, 6, [{:atom, 0, String}, {:atom, 0, :t}, []]}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :version}, {:type, 5, :integer, []}]}
#                ]}, []}
#            ]}},
#          {Extract.Http.Post,
#           {:ok,
#            [
#              type: {:t,
#               {:type, 4, :map,
#                [
#                  {:type, 4, :map_field_exact, [{:atom, 0, :__struct__}, {:atom, 0, Extract.Http.Post}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :body}, {:type, 8, :binary, []}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :headers}, {:type, 7, :map, :any}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :url}, {:remote_type, 6, [{:atom, 0, String}, {:atom, 0, :t}, []]}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :version}, {:type, 5, :integer, []}]}
#                ]}, []}
#            ]}},
#          {Extract.Http.Header,
#           {:ok,
#            [
#              type: {:t,
#               {:type, 4, :map,
#                [
#                  {:type, 4, :map_field_exact, [{:atom, 0, :__struct__}, {:atom, 0, Extract.Http.Header}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :into}, {:remote_type, 7, [{:atom, 0, String}, {:atom, 0, :t}, []]}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :name}, {:remote_type, 6, [{:atom, 0, String}, {:atom, 0, :t}, []]}]},
#                  {:type, 4, :map_field_exact, [{:atom, 0, :version}, {:type, 5, :integer, []}]}
#                ]}, []}
#            ]}}
#        ]
# stacktrace:
#   test/define/protocol_finder_test.exs:6: (test)
#
#
