defmodule Acquire.Query.ST do
  @moduledoc "TODO"

  alias Acquire.Query.Where.{Function, Parameter}

  @spec intersects(term, term) :: {:ok, Function.t()} | {:error, term}
  def intersects(a, b) do
    Function.new(function: "ST_Intersects", args: [a, b])
  end

  @spec intersects!(term, term) :: Function.t()
  def intersects!(a, b) do
    Function.new!(function: "ST_Intersects", args: [a, b])
  end

  @spec point(x :: float, y :: float) :: {:ok, Function.t()} | {:error, term}
  def point(x, y) do
    Ok.transform([x, y], &Parameter.new(value: &1))
    |> Ok.map(&Function.new(function: "ST_Point", args: &1))
  end

  @spec point!(x :: float, y :: float) :: Function.t()
  def point!(x, y) do
    args = Enum.map([x, y], &Parameter.new!(value: &1))
    Function.new!(function: "ST_Point", args: args)
  end
end
