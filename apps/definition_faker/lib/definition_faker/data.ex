defmodule DefinitionFaker.Data do
  @moduledoc false

  def default do
    %{
      version: 1,
      gather_id: Faker.UUID.v4(),
      load_id: Faker.UUID.v4(),
      payload: Faker.Lorem.sentence()
    }
  end
end
