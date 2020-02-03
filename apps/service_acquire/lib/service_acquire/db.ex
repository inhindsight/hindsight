defmodule Acquire.Db do
  # TODO
  @moduledoc false

  @type statement :: String.t()
  @type result :: map

  @callback execute(statement, list) :: Ok.result()
end
