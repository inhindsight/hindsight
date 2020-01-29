defmodule Definition.Schema.Type do
  @moduledoc """
  Defines specifications according to the Norm
  library for `string`, `required_string`, `id`, and `version`
  """

  import Norm
  import Definition.Schema.Validation

  @type spec :: %Norm.Spec{} | %Norm.Spec.And{} | %Norm.Spec.Or{} | %Norm.Spec.Union{}

  @spec required_string() :: spec
  def required_string do
    spec(is_binary() and not_empty?())
  end

  @spec string() :: spec
  def string, do: spec(is_binary())

  @spec version(expected :: integer) :: spec
  def version(expected) do
    spec(fn v -> v == expected end)
  end

  @spec id() :: spec
  def id, do: required_string()

  @spec of_struct(module) :: spec
  def of_struct(module) do
    spec(fn
      %m{} -> m == module
      _ -> false
    end)
  end

  @spec access_path() :: spec
  def access_path() do
    one_of([spec(is_binary()), coll_of(spec(is_binary()))])
  end
end
