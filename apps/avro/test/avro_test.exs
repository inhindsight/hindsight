defmodule AvroTest do
  use ExUnit.Case
  use Placebo

  setup do
    dictionary =
      Dictionary.from_list([
        Dictionary.Type.String.new!(name: "name"),
        Dictionary.Type.Integer.new!(name: "age")
      ])

    [dictionary: dictionary]
  end

  test "will create a new schema from a dictionary", %{dictionary: dictionary} do
    assert {:ok, avro} = Avro.open("people", dictionary)
    on_exit(fn -> File.rm(avro.file_path) end)

    assert {:ok, 209} =
             Avro.write(avro, [
               %{"name" => "joe", "age" => 21},
               %{"name" => "bob", "age" => 23}
             ])

    file = Avro.close(avro)

    assert {header, schema, data} = :avro_ocf.decode_file(file)

    assert Enum.map(data, &Map.new/1) == [
             %{"name" => "joe", "age" => 21},
             %{"name" => "bob", "age" => 23}
           ]
  end

  test "will return error tuple when unable to create file", %{dictionary: dictionary} do
    allow Temp.path(any()), return: {:error, "failure"}

    assert {:error, "failure"} == Avro.open("people", dictionary)
  end

  test "will return an error when unable to open file", %{dictionary: dictionary} do
    allow File.open(any(), any()), return: {:error, "failure"}

    assert {:error, "failure"} == Avro.open("people", dictionary)
  end

  test "returns error tuple when error is raised", %{dictionary: dictionary} do
    allow :avro_ocf.make_header(any()), exec: fn _ -> raise "failure" end

    expected = RuntimeError.exception(message: "failure")
    assert {:error, expected} == Avro.open("people", dictionary)
  end
end
