defmodule DefinitionFaker.Schedule do
  @moduledoc false

  def default do
    %{
      version: 1,
      id: Faker.UUID.v4(),
      dataset_id: Faker.UUID.v4(),
      cron: "5 4 * * *",
      extract: extract(),
      transform: [],
      load: []
    }
  end

  defp extract do
    with default <- DefinitionFaker.Extract.default(),
         {:ok, new_extract} <- Extract.new(default) do
      new_extract
    end
  end
end
