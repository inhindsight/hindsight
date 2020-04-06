defmodule Acquire.Query.ST do
  @moduledoc """
  Collection of functions that generate `Acquire.Query.Where.Function`
  objects representing PrestoDB [ST_*](https://prestosql.io/docs/current/functions/geospatial.html#ST_Intersects) functions.
  """

  alias Acquire.Query.Where.Function
  alias Acquire.Queryable

  import Acquire.Query.Where.Functions, only: [parameter: 1, array: 1]

  @spec geometry_from_text(String.t() | Queryable.t()) :: {:ok, Function.t()} | {:error, term}
  def geometry_from_text(text) when is_binary(text) do
    Function.new(function: "ST_GeometryFromText", args: [parameter(text)])
  end

  def geometry_from_text(text) do
    Function.new(function: "ST_GeometryFromText", args: [text])
  end

  @spec envelope(Queryable.t()) :: {:ok, Function.t()} | {:error, term}
  def envelope(a) do
    Function.new(function: "ST_Envelope", args: [a])
  end

  @spec line_string(Acquire.Query.Where.Array.t() | list) :: {:ok, Function.t()} | {:error, term}
  def line_string(%Acquire.Query.Where.Array{} = array) do
    Function.new(function: "ST_LineString", args: [array])
  end

  def line_string(list) when is_list(list) do
    Function.new(function: "ST_LineString", args: [array(list)])
  end

  @spec intersects(Queryable.t(), Queryable.t()) :: {:ok, Function.t()} | {:error, term}
  def intersects(a, b) do
    Function.new(function: "ST_Intersects", args: [a, b])
  end

  @spec intersects!(Queryable.t(), Queryable.t()) :: Function.t()
  def intersects!(a, b) do
    case intersects(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @spec point(x :: float | Queryable.t(), y :: float | Queryable.t()) ::
          {:ok, Function.t()} | {:error, term}
  def point(x, y) when is_float(x) and is_float(y) do
    point(parameter(x), parameter(y))
  end

  def point(x, y) do
    Function.new(function: "ST_Point", args: [x, y])
  end

  @spec point!(x :: float | Queryable.t(), y :: float | Queryable.t()) :: Function.t()
  def point!(x, y) do
    case point(x, y) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end
end
