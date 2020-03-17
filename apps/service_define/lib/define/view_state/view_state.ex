defmodule ViewState do

  def event(state, event) do

    case event do
      %{ "type" => "new_greeting" } -> Map.put(state, "greeting", Map.get(event, "greeting"))
      _ -> state
    end

  end

end
