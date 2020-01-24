defmodule Acquire.Query do
  @moduledoc "TODO"

  @type statement :: String.t()

  @spec translate(params :: map) :: {:ok, statement} | {:error, term}
  def translate(%{"dataset" => ds} = params) do
    subset = Map.get(params, "subset", "default")
    {:ok, "select * from #{ds}__#{subset}"}
  end
end
