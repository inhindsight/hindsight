defmodule Gather.Case do
  use ExUnit.CaseTemplate

  setup do
    instance = Gather.Application.instance()
    collection = Gather.Extraction.Store.collection()
    Brook.Test.clear_view_state(instance, collection)

    :ok
  end
end
