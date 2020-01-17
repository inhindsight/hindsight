defmodule Persist.Dictionary.Translator.Result do
  defstruct [:name, :type]
end

defprotocol Persist.Dictionary.Translator do
  @spec translate_type(t) :: %Persist.Dictionary.Translator.Result{}
  def translate_type(field)

  @spec translate_value(t, value :: term) :: term
  def translate_value(field, value)
end

defmodule Persist.Dictionary do
  alias Persist.Dictionary.Translator
  alias Persist.Dictionary.Translator.Result

  defimpl Translator, for: Dictionary.Type.String do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "varchar"}
    end

    def translate_value(_field, value), do: value
  end

  defimpl Translator, for: Dictionary.Type.Integer do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "integer"}
    end

    def translate_value(_field, value), do: value
  end

  defimpl Translator, for: Dictionary.Type.Map do
    def translate_type(%{name: name, fields: fields}) do
      row_def =
        fields
        |> Enum.map(&Translator.translate_type(&1))
        |> Enum.map(fn result -> "#{result.name} #{result.type}" end)
        |> Enum.join(",")

      %Result{name: name, type: "row(#{row_def})"}
    end

    def translate_value(%{fields: fields}, value) do
      fields
      |> Enum.map(fn field -> {field, Map.get(value, field.name)} end)
      |> Enum.map(fn {field, value} -> Translator.translate_value(field, value) end)
      |> List.to_tuple()
    end
  end

  defimpl Translator, for: Dictionary.Type.List do
    def translate_type(%{name: name, item_type: item_type, fields: fields}) do
      sub_field = struct(item_type, name: "fake", fields: fields)
      sub_result = Translator.translate_type(sub_field)
      %Result{name: name, type: "array(#{sub_result.type})"}
    end

    def translate_value(%{item_type: Dictionary.Type.Map, fields: fields}, value) do
      map_type = %Dictionary.Type.Map{fields: fields}
      Enum.map(value, &Translator.translate_value(map_type, &1))
    end

    def translate_value(_, value), do: value
  end
end
