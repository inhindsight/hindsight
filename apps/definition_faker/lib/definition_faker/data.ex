defmodule DefinitionFaker.Data do
  @moduledoc false

  def default do
    %{
      version: 1,
      gather_id: Faker.UUID.v4(),
      load_id: Faker.UUID.v4(),
      payload: %{"a" => Faker.Lorem.sentence(), "b" => Faker.Util.digit()}
    }
  end
end
