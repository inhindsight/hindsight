defmodule SecretStore do
  @moduledoc """
  Behaviour for reading secrets into Hindsight from outside the system.
  """
  use Properties, otp_app: :secret_store

  getter(:secret_environment, required: true)

  @spec environment() :: String.t()
  def environment, do: secret_environment()

  @typedoc "Base identifier for a secret."
  @type id :: String.t()

  @typedoc "Key used to specify a secret value."
  @type key :: String.t() | nil

  @typedoc "Secret value returned from a store."
  @type value :: String.t()

  @callback get(id, key, default) :: value | default when default: term
end
