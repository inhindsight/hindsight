defmodule Gather.Case do
  use ExUnit.CaseTemplate
  alias Gather.ViewState.{Extractions, Sources, Destinations}

  setup do
    instance = Gather.Application.instance()

    on_exit(fn ->
      [Extractions.collection(), Sources.collection(), Destinations.collection()]
      |> Enum.each(&Brook.Test.clear_view_state(instance, &1))
    end)

    :ok
  end
end
