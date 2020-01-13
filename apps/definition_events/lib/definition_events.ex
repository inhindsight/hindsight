defmodule Definition.Events do
  defmacro extract_start(), do: "extract:start"

  defmacro extract_end(), do: "extract:end"

  defmacro load_stream_start(), do: "load:stream:start"

  defmacro load_stream_end(), do: "load:stream:end"
end
