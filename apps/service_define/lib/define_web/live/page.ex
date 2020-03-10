defmodule DefineWeb.Page do
  use Phoenix.LiveView
  import Phoenix.HTML.Form
  alias Define.User
  import DefineWeb.ErrorHelpers

  def mount(_params, _session, socket) do
    user = %User{}
    changeset = User.create_user()
    {:ok, assign(socket, user: user, changeset: changeset)}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>We did it!</h1>
      <%= f = form_for @changeset, "#", [phx_change: :validate, phx_submit: :save] %>
        <%= label f, :first %>
        <%= text_input f, :first %>
        <%= error_tag f, :first %>

        <%= label f, :last %>
        <%= text_input f, :last %>
        <%= error_tag f, :last %>

        <%= label f, :age %>
        <%= text_input f, :age %>
        <%= error_tag f, :age %>

        <%= submit "Save" %>
      </form>
    </div>
    """
  end

  def handle_event("validate", %{"user" => params}, socket) do
    changeset = 
      socket.assigns.user
      |> User.change_user(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"user" => params}, socket) do
    User.update_user(socket.assigns.user, params)
    |> User.to_struct()

    {:noreply, socket}
  end
end
