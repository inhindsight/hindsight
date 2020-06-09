defmodule Decoder.JsonArraysTest do
  use ExUnit.Case

  test "serialization" do
    struct = Decoder.JsonArrays.new!([])

    serialized = JsonSerde.serialize!(struct)

    assert JsonSerde.deserialize!(serialized) == struct
  end

  describe "Decoder" do
    test "decodes string with arrays to json" do
      input = [
        ~s([{"id":"1","type":"Crew","position":[0, 1, 2]}, {"id":"2","type":"Crew","position":[3,4,5]},{"id":"3","type":"Guest","position":[6,7,8]}]),
        ~s([{"id":"4","type":"Crew","position":[0, 1, 2]}, {"id":"5","type":"Crew","position":[3,4,5]},{"id":"6","type":"Guest","position":[6,7,8]}]),
        ~s([{"id":"7","type":"Crew","position":[0, 1, 2]}])
      ]

      output = Decoder.decode(Decoder.JsonArrays.new!([]), input)

      assert output == [
               %{"id" => "1", "type" => "Crew", "position" => [0, 1, 2]},
               %{"id" => "2", "type" => "Crew", "position" => [3, 4, 5]},
               %{"id" => "3", "type" => "Guest", "position" => [6, 7, 8]},
               %{"id" => "4", "type" => "Crew", "position" => [0, 1, 2]},
               %{"id" => "5", "type" => "Crew", "position" => [3, 4, 5]},
               %{"id" => "6", "type" => "Guest", "position" => [6, 7, 8]},
               %{"id" => "7", "type" => "Crew", "position" => [0, 1, 2]}
             ]
    end
  end
end
