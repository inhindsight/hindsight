defmodule Persist.DLQ do
  use Writer.DLQ, name: __MODULE__
end
