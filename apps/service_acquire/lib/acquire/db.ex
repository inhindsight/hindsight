defmodule Acquire.Db do
  @moduledoc false

  @type statement :: String.t()
  @type result :: map

  @callback execute(statement, list) :: Ok.result()
end
