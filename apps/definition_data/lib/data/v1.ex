defmodule Data.V1 do
  @moduledoc """
  Defines the data message implementation of
  the `Definition.Schema` behaviour and the
  `s/0` function.

  Returns a valid Norm schema representing a data
  message for validation and defaults the current
  struct version.
  """
  use Definition.Schema

  @impl true
  def s do
    schema(%Data{
      version: version(1),
      dataset_id: id(),
      extract_id: id(),
      payload: schema(%{})
    })
  end
end
