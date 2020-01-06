defmodule Writer.Presto.Dictionary.Translator.Result do
  defstruct [:name, :type]
end

defprotocol Writer.Presto.Dictionary.Translator do
  @spec translate(t) :: %Writer.Presto.Dictionary.Translator.Result{}
  def translate(field)
end

defmodule Writer.Presto.Dictionary do
  alias Writer.Presto.Dictionary.Translator
  alias Writer.Presto.Dictionary.Translator.Result

  defimpl Translator, for: Dictionary.Type.String do
    def translate(%{name: name}) do
      %Result{name: name, type: "varchar"}
    end
  end

  defimpl Translator, for: Dictionary.Type.Integer do
    def translate(%{name: name}) do
      %Result{name: name, type: "integer"}
    end
  end

  defimpl Translator, for: Dictionary.Type.Map do
    def translate(%{name: name, fields: fields}) do
      row_def =
        fields
        |> Enum.map(&Translator.translate(&1))
        |> Enum.map(fn result -> "#{result.name} #{result.type}" end)
        |> Enum.join(",")

      %Result{name: name, type: "row(#{row_def})"}
    end
  end

  defimpl Translator, for: Dictionary.Type.List do
    def translate(%{name: name, item_type: item_type, fields: fields}) do
      sub_field = struct(item_type, name: "fake", fields: fields)
      sub_result = Translator.translate(sub_field)
      %Result{name: name, type: "array(#{sub_result.type})"}
    end
  end
end
