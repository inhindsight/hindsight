defmodule Presto.Table.Dictionary.Translator.Result do
  defstruct [:name, :type]
end

defprotocol Presto.Table.Dictionary.Translator do
  @spec translate_type(t) :: %Presto.Table.Dictionary.Translator.Result{}
  def translate_type(field)

  @spec translate_value(t, value :: term) :: term
  def translate_value(field, value)
end

defmodule Presto.Table.Dictionary do
  alias Presto.Table.Dictionary.Translator
  alias Presto.Table.Dictionary.Translator.Result

  defimpl Translator, for: Dictionary.Type.String do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "varchar"}
    end

    def translate_value(_field, value), do: "'#{value}'"
  end

  defimpl Translator, for: Dictionary.Type.Wkt.Point do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "varchar"}
    end

    def translate_value(_field, value), do: "'#{value}'"
  end

  defimpl Translator, for: Dictionary.Type.Integer do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "bigint"}
    end

    def translate_value(_field, value), do: value
  end

  defimpl Translator, for: Dictionary.Type.Float do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "double"}
    end

    def translate_value(_field, value), do: value
  end

  defimpl Translator, for: Dictionary.Type.Boolean do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "boolean"}
    end

    def translate_value(_field, value), do: value
  end

  defimpl Translator, for: Dictionary.Type.Date do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "date"}
    end

    def translate_value(_field, value) do
      "date('#{value}')"
    end
  end

  defimpl Translator, for: Dictionary.Type.Timestamp do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "timestamp"}
    end

    def translate_value(_field, value) do
      date_format =
        cond do
          String.length(value) == 19 -> "'%Y-%m-%dT%H:%i:%S'"
          String.length(value) == 20 -> "'%Y-%m-%dT%H:%i:%SZ'"
          String.ends_with?(value, "Z") -> "'%Y-%m-%dT%H:%i:%S.%fZ'"
          true -> "'%Y-%m-%dT%H:%i:%S.%f'"
        end

      "date_parse('#{value}', #{date_format})"
    end
  end

  defimpl Translator, for: Dictionary.Type.Longitude do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "double"}
    end

    def translate_value(_field, value) do
      value
    end
  end

  defimpl Translator, for: Dictionary.Type.Latitude do
    def translate_type(%{name: name}) do
      %Result{name: name, type: "double"}
    end

    def translate_value(_field, value) do
      value
    end
  end

  defimpl Translator, for: Dictionary.Type.Map do
    def translate_type(%{name: name, dictionary: dictionary}) do
      row_def =
        dictionary
        |> Enum.map(&Translator.translate_type(&1))
        |> Enum.map(fn result -> "#{result.name} #{result.type}" end)
        |> Enum.join(",")

      %Result{name: name, type: "row(#{row_def})"}
    end

    def translate_value(%{dictionary: dictionary}, value) do
      values =
        dictionary
        |> Enum.map(fn field -> {field, Map.get(value, field.name)} end)
        |> Enum.map(fn {field, value} -> Translator.translate_value(field, value) end)

      "row(#{Enum.join(values, ",")})"
    end
  end

  defimpl Translator, for: Dictionary.Type.List do
    def translate_type(%{name: name, item_type: item_type}) do
      sub_result = Translator.translate_type(item_type)
      %Result{name: name, type: "array(#{sub_result.type})"}
    end

    def translate_value(%{item_type: item_type}, list) do
      values = Enum.map(list, &Translator.translate_value(item_type, &1))

      "array[#{Enum.join(values, ",")}]"
    end
  end
end
