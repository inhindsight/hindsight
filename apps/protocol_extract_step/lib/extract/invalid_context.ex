defmodule Extract.InvalidContextError do
  @moduledoc false
  defexception [:message, :step]
end
