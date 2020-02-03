defmodule Acquire.Query.ST.Intersects do
  @spec new(term, term) :: {:ok, Acquire.Query.Where.Function.t()} | {:error, term}
  def new(a, b) do
    Acquire.Query.Where.Function.new(function: "ST_Intersects", args: [a, b])
  end

  @spec new(term, term) :: Acquire.Query.Where.Function.t()
  def new!(a, b) do
    Acquire.Query.Where.Function.new!(function: "ST_Intersects", args: [a, b])
  end
end
