defmodule Acquire.Query.Where.Functions do
  alias Acquire.Query.Where.{Array, Field, Function, Literal, Parameter}
  alias Acquire.Queryable

  @spec parameter(term) :: Parameter.t()
  def parameter(value) do
    Parameter.new!(value: value)
  end

  @spec literal(String.Chars.t()) :: Literal.t()
  def literal(value) do
    Literal.new!(value: value)
  end

  @spec field(String.t()) :: Field.t()
  def field(name) do
    Field.new!(name: name)
  end

  @spec array([Queryable.t()]) :: Array.t()
  def array(elements) do
    Array.new!(elements: elements)
  end

  @spec gt(Queryable.t(), Queryable.t()) :: Function.t()
  def gt(a, b) do
    Function.new!(
      function: ">",
      args: [a, b]
    )
  end

  @spec gte(Queryable.t(), Queryable.t()) :: Function.t()
  def gte(a, b) do
    Function.new!(
      function: ">=",
      args: [a, b]
    )
  end

  @spec lt(Queryable.t(), Queryable.t()) :: Function.t()
  def lt(a, b) do
    Function.new!(
      function: "<",
      args: [a, b]
    )
  end

  @spec lte(Queryable.t(), Queryable.t()) :: Function.t()
  def lte(a, b) do
    Function.new!(
      function: "<=",
      args: [a, b]
    )
  end

  @spec date_parse(Queryable.t(), Queryable.t()) :: Function.t()
  def date_parse(timestamp, format) do
    Function.new!(
      function: "date_parse",
      args: [
        timestamp,
        format
      ]
    )
  end

  @spec date_diff(Queryable.t(), Queryable.t()) :: Function.t()
  def date_diff(timestamp1, timestamp2) do
    Function.new!(
      function: "date_diff",
      args: [
        literal("millisecond"),
        timestamp1,
        timestamp2
      ]
    )
  end
end
