defmodule Define.ViewState do
  use GenServer

  alias Define.Model.AppView
  alias Define.Event.Store

  def init(state) do
    {:ok, state}
  end

  def start_link(init_opts) do
    server_opts = Keyword.take(init_opts, [:name])
    GenServer.start_link(__MODULE__, default_state(), server_opts)
  end

  defp default_state() do
    %AppView{
      data_definitions: Store.get_all()
    }
  end
end
