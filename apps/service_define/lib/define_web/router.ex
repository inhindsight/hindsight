defmodule DefineWeb.Router do
  use DefineWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", DefineWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

end
