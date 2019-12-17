defmodule Definition.Schema.ValidationTest do
  use ExUnit.Case
  use ExUnitProperties

  import Definition.Schema.Validation

  describe "ts?/1" do
    test "returns true with valid ISO8601 timestamp" do
      valid = DateTime.utc_now() |> DateTime.to_iso8601()
      assert ts?(valid)
    end

    property "returns false for other inputs" do
      check all input <- term() do
        refute ts?(input)
      end
    end
  end

  describe "temporal_range?/1" do
    test "returns true with valid temporal range" do
      start = DateTime.utc_now() |> DateTime.to_iso8601()
      stop = DateTime.utc_now() |> DateTime.to_iso8601()

      assert temporal_range?([start, stop])
    end

    test "returns false for valid timestammps out of order" do
      start = DateTime.utc_now() |> DateTime.to_iso8601()
      stop = DateTime.utc_now() |> DateTime.to_iso8601()

      refute temporal_range?([stop, start])
    end

    property "returns false for other inputs" do
      check all input <- term() do
        refute temporal_range?(input)
      end
    end
  end

  describe "bbox?/1" do
    setup do
      x = Faker.Address.latitude()
      y = Faker.Address.longitude()
      [x: x, y: y]
    end

    test "returns true with geospatial point", %{x: x, y: y} do
      assert bbox?([x, y, x, y])
    end

    test "returns true with geospatial bounding box", %{x: x, y: y} do
      assert bbox?([x, y, x + 1, y + 1])
    end

    test "returns false with invalid bounding box", %{x: x, y: y} do
      refute bbox?([x, y, x - 1, y - 1])
    end

    property "returns false for other inputs" do
      check all input <- term() do
        refute bbox?(input)
      end
    end
  end

  describe "email?/1" do
    test "returns true for valid email address" do
      assert email?("foo@bar.com")
      refute email?("@foobar.com")
    end

    property "returns false for any other input" do
      check all input <- term() do
        refute email?(input)
      end
    end
  end

  describe "empty?/1" do
    test "returns true for empty string/list/map" do
      assert empty?("")
      assert empty?([])
      assert empty?(%{})
    end

    test "returns true for string with only space characters" do
      assert empty?("    ")
      assert empty?("\t\n")
    end

    test "returns false for any other input" do
      check all input <- term(),
        input != [],
        input != "",
        input != %{} do
        refute empty?(input)
      end
    end
  end

  describe "not_empty?/1" do
    test "returns true for non-empty strings/lists/maps" do
      assert not_empty?("foo")
      assert not_empty?(["a"])
      assert not_empty?(%{a: "foo"})
    end

    test "returns false for string with only space characters" do
      refute not_empty?("    ")
      refute not_empty?("\t\n")
    end

    property "returns true for any other input" do
      check all input <- term(),
                input != [],
                input != "",
                input != %{} do
        assert not_empty?(input)
      end
    end
  end
end
