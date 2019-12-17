defmodule DatasetFaker.Owner do
  @moduledoc false

  def default do
    title = "#{Faker.Color.It.name()}_#{Faker.Cat.name()}"

    %{
      version: 1,
      id: Faker.UUID.v4(),
      name: String.downcase(title),
      title: title,
      description: Faker.Lorem.sentences() |> Enum.join(" "),
      url: Faker.Internet.domain_name(),
      image: Faker.Internet.image_url(),
      contact: %{
        name: Faker.Name.name(),
        email: Faker.Internet.email()
      }
    }
  end
end
