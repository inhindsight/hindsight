defmodule Define.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :first, :string
    field :last, :string
    field :age, :integer
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first, :last, :age])
    |> validate_length(:first, min: 2)
  end

  def create_user(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def change_user(user, attrs \\ %{}) do
    changeset(user, attrs)
  end

  def update_user(%__MODULE__{} = user, attrs) do
    user
    |> changeset(attrs)
  end

  def to_struct(changeset) do
    apply_changes(changeset)
  end
end
