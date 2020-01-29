defmodule PlatformRunner.AcquireClient do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "http://localhost:4001/api/v2")
  plug(Tesla.Middleware.JSON)

  def data(path) do
    get("/data/#{path}")
    |> Ok.map(& &1.body)
  end
end
