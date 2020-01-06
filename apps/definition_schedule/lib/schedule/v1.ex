defmodule Schedule.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Schedule{
      version: spec(fn v -> v == 1 end),
      id: spec(is_binary() and not_empty?()),
      dataset_id: spec(is_binary() and not_empty?()),
      cron: spec(is_binary() and not_empty?()),
      extract: Extract.schema(),
      transform: Transform.schema(),
      load: spec(is_list())
    })
  end
end
