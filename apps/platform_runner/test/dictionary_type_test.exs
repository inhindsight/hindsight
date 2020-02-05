defmodule Dictionary.Type.Test do
  use ExUnit.Case

  @protocols [
    Jason.Encoder,
    Dictionary.Type.Normalizer,
    Persist.Dictionary.Translator,
    Avro.Translator
  ]

  test "all dictionary types implment correct protocols" do
    for module <- get_dictionary_types(),
        protocol <- @protocols do
      assert_impl(protocol, module)
    end
  end

  defp get_dictionary_types() do
    {:ok, modules} = :application.get_key(:definition_dictionary, :modules)

    modules
    |> Enum.filter(fn x -> to_string(x) =~ ~r/^Elixir\.Dictionary\.Type\.[\w_]+$/ end)
    |> Enum.reject(&String.contains?(to_string(&1), "Normalizer"))
  end

  defp assert_impl(protocol, impl) do
    Protocol.assert_impl!(protocol, impl)
  rescue
    _e -> flunk("#{impl} does not implement the protocol #{protocol}")
  end
end
