defmodule Acquire.Query.ST.Intersects do
  @spec new(term, term) :: {:ok, Acquire.Query.Function.t()} | {:error, term}
  def new(a, b) do
    Acquire.Query.Function.new(function: "ST_Intersects", args: [a, b])
  end

  @spec new(term, term) :: Acquire.Query.Function.t()
  def new!(a, b) do
    Acquire.Query.Function.new!(function: "ST_Intersects", args: [a, b])
  end
end
