defmodule DefineWeb.PageController do
  use DefineWeb, :controller

  def index(conn, _params) do
    path =
      DefineWeb.Endpoint.config(:otp_app)
      |> :code.priv_dir()
      |> Path.join("static/index.html")

    html(conn, File.read!(path))
  end
end
