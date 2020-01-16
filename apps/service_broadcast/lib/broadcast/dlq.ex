defmodule Broadcast.DLQ do
  use Writer.DLQ, name: __MODULE__
end
