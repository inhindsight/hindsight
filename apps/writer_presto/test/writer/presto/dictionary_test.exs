defmodule Writer.Presto.DictionaryTest do
  use ExUnit.Case
  import Checkov

  alias Writer.Presto.Dictionary.Translator
  alias Writer.Presto.Dictionary.Translator.Result

  data_test "something, something, translate" do
    result = Translator.translate(field)

    assert expected == result

    where [
      [:field, :expected],
      [%Dictionary.Type.String{name: "name"}, %Result{name: "name", type: "varchar"}],
      [%Dictionary.Type.Integer{name: "age"}, %Result{name: "age", type: "integer"}],
      [
        %Dictionary.Type.Map{
          name: "spouse",
          fields: [%Dictionary.Type.String{name: "name"}, %Dictionary.Type.Integer{name: "age"}]
        },
        %Result{name: "spouse", type: "row(name varchar,age integer)"}
      ],
      [
        %Dictionary.Type.List{name: "colors", item_type: Dictionary.Type.String},
        %Result{name: "colors", type: "array(varchar)"}
      ],
      [
        %Dictionary.Type.List{
          name: "friends",
          item_type: Dictionary.Type.Map,
          fields: [%Dictionary.Type.String{name: "name"}, %Dictionary.Type.Integer{name: "age"}]
        },
        %Result{name: "friends", type: "array(row(name varchar,age integer))"}
      ]
    ]
  end
end
