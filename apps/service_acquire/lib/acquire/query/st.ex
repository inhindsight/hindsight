defmodule Acquire.Query.ST do
  @moduledoc "TODO"

  alias Acquire.Query.Where.{Function, Parameter}

  @spec intersects(term, term) :: {:ok, Function.t()} | {:error, term}
  def intersects(a, b) do
    Function.new(function: "ST_Intersects", args: [a, b])
  end

  @spec intersects!(term, term) :: Function.t()
  def intersects!(a, b) do
    case intersects(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  # def envelope(geometry) do
  #   Function.new(function: "ST_Envelope", args: [geometry])
  # end

  @spec point(x :: float, y :: float) :: {:ok, Function.t()} | {:error, term}
  def point(x, y) do
    Ok.transform([x, y], &Parameter.new(value: &1))
    |> Ok.map(&Function.new(function: "ST_Point", args: &1))
  end

  @spec point!(x :: float, y :: float) :: Function.t()
  def point!(x, y) do
    case point(x, y) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end
end
