defmodule AcquireWeb.Router do
  use AcquireWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AcquireWeb do
    pipe_through :api
  end
end
