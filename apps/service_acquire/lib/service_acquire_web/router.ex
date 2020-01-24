defmodule AcquireWeb.Router do
  use AcquireWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v2", AcquireWeb.V2 do
    pipe_through :api

    get "/data/:dataset/:subset", DataController, :select
  end
end
