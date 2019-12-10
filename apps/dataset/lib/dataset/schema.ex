defmodule Dataset.Schema do
  @moduledoc "TODO"

  import Norm
  import Dataset.Schema.Validation

  def timestamp, do: spec(is_binary() and ts?())
  def string, do: spec(is_binary() and not_empty?())
  def contact, do: schema(%{name: string(), email: spec(email?())})
  def geo_spatial, do: spec(is_list() and bbox?())
  def temporal, do: spec(is_list() and ts?() and temporal_range?())

  def boundaries do
    schema(%{
      spatial: geo_spatial(),
      temporal: temporal()
    })
  end
end
