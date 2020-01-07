defmodule Definition.Schema.Type do
  import Norm
  import Definition.Schema.Validation

  @type spec :: %Norm.Spec{} | %Norm.Spec.And{} | %Norm.Spec.Or{}

  @spec required_string() :: spec
  def required_string do
    spec(is_binary() and not_empty?())
  end

  @spec version(expected :: integer) :: spec
  def version(expected) do
    spec(fn v -> v == expected end)
  end

  @spec id() :: spec
  def id, do: required_string()
end
