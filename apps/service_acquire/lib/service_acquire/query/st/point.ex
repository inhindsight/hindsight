defmodule Acquire.Query.ST.Point do
  alias Acquire.Query.{Function, Parameter}

  @spec new(x :: float, y :: float) :: {:ok, Function.t()} | {:error, term}
  def new(x, y) do
    Ok.transform([x, y], &Parameter.new(value: &1))
    |> Ok.map(&Function.new(function: "ST_Point", args: &1))
  end

  @spec new(x :: float, y :: float) :: Function.t()
  def new!(x, y) do
    args = Enum.map([x, y], &Parameter.new!(value: &1))
    Function.new!(function: "ST_Point", args: args)
  end
end
