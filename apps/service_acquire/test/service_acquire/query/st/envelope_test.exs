defmodule Acquire.Query.ST.EnvelopeTest do
  use ExUnit.Case

  alias Acquire.Query.ST.Envelope
  alias Acquire.Query.Where.{Function, Parameter}
  alias Acquire.Queryable

  describe "parsing" do
    test "parses ST_Envelope" do
      fun = Function.new!(function: "foo", args: ["bar", Parameter.new!(value: 42)])
      envelope = Envelope.new!(geometry: fun)

      assert Queryable.parse_statement(envelope) == "ST_Envelope(foo(bar, ?))"
      assert Queryable.parse_input(envelope) == [42]
    end
  end

end
