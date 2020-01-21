# Dataset.Owner

Dataset.Owner defines the structure for tracking the ownership
of datasets within Hindsight. Dataset.Owner inherits the schema
validation as well as the struct instance creation and lifecycle
management functions from the root Definition library.

```
    Definition
        |_ Dataset.Owner
```

The Dataset.Owner struct collects the identifier and name for the
owner, descriptors for branding and directing users to the owner
such as title, description, url, and image (logo) uri, as well as
contact information to reach an individual attached to the owning
entity.

## Usage

```elixir
  iex> Dataset.Owner.new(
                          version: 1,
                          id: "123-456",
                          name: "SteveCo",
                          description: "Steve's really cool company",
                          url: "steve.co",
                          image: "https://imagesource.cdn.com/steveco.png"
                          contact: %{
                            name: "Steve Stevenson",
                            email: "me@steve.co"
                          }
  {:ok, %Dataset.Owner{ ... same as above ... }}
```

## Installation

```elixir
def deps do
  [
    {:definition_dataset_owner, in_umbrella: true}
  ]
end
```
