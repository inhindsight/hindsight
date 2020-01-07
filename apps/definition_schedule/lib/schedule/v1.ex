defmodule Schedule.V1 do
  use Definition.Schema

  @impl Definition.Schema
  def s do
    schema(%Schedule{
      version: version(1),
      id: id(),
      dataset_id: id(),
      cron: required_string(),
      extract: Extract.schema(),
      transform: Transform.schema(),
      load: spec(is_list())
    })
  end
end
