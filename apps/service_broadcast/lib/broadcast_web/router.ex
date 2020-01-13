defmodule BroadcastWeb.Router do
  use BroadcastWeb, :router

  @dialyzer [:no_return, :no_match]

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", BroadcastWeb do
    pipe_through :api
  end
end
