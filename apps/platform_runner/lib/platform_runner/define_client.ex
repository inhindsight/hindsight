defmodule PlatformRunner.DefineClient do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://localhost:4005/")
  plug(Tesla.Middleware.JSON)

  def root() do
    get("")
    |> Ok.map(& &1.body)
  end
end
