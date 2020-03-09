defmodule DefineWeb.Router do
  use DefineWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DefineWeb do
    pipe_through :browser

    live "/", Page
  end

  # Other scopes may use custom stacks.
  # scope "/api", DefineWeb do
  #   pipe_through :api
  # end
end
