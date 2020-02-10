defmodule Acquire.Query.Where.Functions do

  alias Acquire.Query.Where.{Function, Parameter}

  def parameter(value) do
    Parameter.new!(value: value)
  end

  def gt(a, b) do
    Function.new!(
      function: ">",
      args: [a, b]
    )
  end

  def gte(a, b) do
    Function.new!(
      function: ">=",
      args: [a, b]
    )
  end

  def lt(a, b) do
    Function.new!(
      function: "<",
      args: [a, b]
    )
  end

  def lte(a, b) do
    Function.new!(
      function: "<=",
      args: [a, b]
    )
  end

  def date_parse(timestamp, format) do
    Function.new!(
      function: "date_parse",
      args: [
        timestamp,
        format
      ]
    )
  end

  def date_diff(timestamp1, timestamp2) do
    Function.new!(
      function: "date_diff",
      args: [
        "'millisecond'",
        timestamp1,
        timestamp2,
      ]
    )
  end
end
