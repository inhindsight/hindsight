defmodule DefineWeb.Page do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>We did it!</h1>
      <button phx-click="dec">HERE</button>
    </div>
    """
  end

  def handle_event("dec", _, socket) do
    socket |> IO.inspect(label: "lib/define_web/live/page.ex:18") 
    {:noreply, socket}
  end
end
