defmodule DefineWeb.Page do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h1>We did it</h1>
    """
  end
end

