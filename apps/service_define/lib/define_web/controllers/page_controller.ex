defmodule DefineWeb.PageController do
  use DefineWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
