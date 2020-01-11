defmodule BroadcastWeb.Router do
  use BroadcastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BroadcastWeb do
    pipe_through :api
  end
end
