defmodule Acquire.Query do
  @moduledoc "TODO"

  @type statement :: String.t()

  @spec from_params(params :: map) :: {:ok, statement} | {:error, term}
  def from_params(%{"dataset" => ds} = params) do
    subset = Map.get(params, "subset", "default")
    {:ok, "select * from #{ds}__#{subset}"}
  end
end
