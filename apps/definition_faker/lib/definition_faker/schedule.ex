defmodule DefinitionFaker.Schedule do
  @moduledoc false

  def default do
    %{
      version: 1,
      id: Faker.UUID.v4(),
      dataset_id: Faker.UUID.v4(),
      cron: "5 4 * * *",
      extract: extract(),
      transform: transform(),
      load: []
    }
  end

  defp extract do
    with {:ok, event} <- DefinitionFaker.extract(%{}) do
      event
    end
  end

  defp transform do
    with {:ok, event} <- DefinitionFaker.transform(%{}) do
      event
    end
  end
end
