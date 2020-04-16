defmodule Define.TypespecAnalysis do
  import Logger

  def find do
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
    case Code.Typespec.fetch_types(module) do
      {:ok, [type_spec]} ->
        extract_fields(type_spec)

      {:ok, []} ->
        %{}

      :error ->
        Logger.error("Unable to get types for #{module}")
        raise(ArgumentError, "Unable to get types for #{module}")
    end
  end

  defp extract_fields([]), do: []

  defp extract_fields({:type, {:t, {:type, _, :map, fields}, _}}) do
    fields
    |> Enum.map(&extract_field_type/1)
    |> Enum.map(&to_simple_type/1)
    |> Enum.reject(&is_meta_field/1)
    |> Enum.into(%{})
  end

  defp extract_field_type({:type, _, _, [{_, _, name}, {_, _, type}]}), do: {name, type, nil}

  defp extract_field_type({:type, _, _, [{_, _, name}, {_, _, type, sub_typespec}]}),
    do: {name, type, sub_typespec}

  defp to_simple_type({name, :list, [{_, _, [{_, _, String}, _, _]}]}),
    do: {to_string(name), {"list", "string"}}

  defp to_simple_type({name, :list, [{_, _, type, _}]}),
    do: {to_string(name), {"list", to_string(type)}}

  defp to_simple_type({name, typespec, _}) do
    type =
      case typespec do
        [{_, _, String}, _, _] -> "string"
        [{_, _, Dictionary}, _, _] -> "dictionary"
        _ -> typespec
      end

    {to_string(name), to_string(type)}
  end

  defp is_meta_field({"__struct__", _}), do: true
  defp is_meta_field({"version", _}), do: true
  defp is_meta_field(_), do: false
end
