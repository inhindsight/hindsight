defmodule Schedule.V1 do
  use Definition.Schema

  @impl true
  def s do
    schema(%Schedule{
      version: version(1),
      id: id(),
      dataset_id: required_string(),
      subset_id: required_string(),
      cron: required_string(),
      extract: Extract.schema(),
      transform: Transform.schema(),
      load: spec(is_list())
    })
  end
end
