defmodule Define.DefinitionSerialization do
  @moduledoc """
  Transforms structs from events into internal representations used for the UI.
  """
  alias Define.Model.{ModuleFunctionArgsView, ArgumentView, TypespecAnalysis}
  alias Define.TypespecAnalysis

  @spec serialize(%Dictionary.Impl{} | list(map()) | map()) :: %ModuleFunctionArgsView{} | list(%ModuleFunctionArgsView{})
  def serialize(%Dictionary.Impl{ordered: ordered}) do
    serialize(ordered)
  end

  def serialize(definitions) when is_list(definitions) do
    Enum.map(definitions, &to_module_function_args_view/1)
  end

  def serialize(definition) do
    to_module_function_args_view(definition)
  end

  defp to_module_function_args_view(definition) do
    struct_name = definition.__struct__

    %ModuleFunctionArgsView{
      struct_module_name: to_string(struct_name),
      args: to_list_of_argument_views(struct_name, definition)
    }
  end

  defp to_list_of_argument_views(struct_name, definition) do
    struct_name
    |> TypespecAnalysis.get_types()
    |> Map.delete(:version)
    |> Enum.map(fn {arg_name, _} = arg_to_type ->
      arg_value = Map.get(definition, String.to_atom(arg_name))
      to_argument_view(arg_to_type, arg_value)
    end)
  end

  defp to_argument_view({_, "dictionary"}, %Dictionary.Type.Map{} = map_definition) do
    value = to_module_function_args_view(map_definition)
    %ArgumentView{key: "dictionary", type: {"list", "module"}, value: value}
  end

  defp to_argument_view({_, "dictionary"}, dictionary) do
    value = dictionary |> Dictionary.from_list() |> serialize()
    %ArgumentView{key: "dictionary", type: {"list", "module"}, value: value}
  end

  defp to_argument_view({_, "module"}, dictionary) do
    [value] = [dictionary] |> Dictionary.from_list() |> serialize()
    %ArgumentView{key: "item_type", type: "module", value: value}
  end

  defp to_argument_view({field_key, field_value_type}, value) do
    %ArgumentView{key: field_key, type: field_value_type, value: value}
  end
end
