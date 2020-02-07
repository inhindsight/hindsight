defmodule Dictionary.Type.Test do
  use ExUnit.Case

  @protocols [
    Jason.Encoder,
    Dictionary.Type.Normalizer,
    Persist.Dictionary.Translator,
    Avro.Translator
  ]

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  def row() do
    text =
    5..104
    |> Enum.map(fn i ->
      random_string(div(i, 5))
    end)
    |> Enum.join(",")

    text <> "\n"
  end

  test "stuff" do
    row()
    |> byte_size()
    |> IO.inspect
  end

  test "all dictionary types implment correct protocols" do
    for module <- get_dictionary_types(),
        protocol <- @protocols do
      assert_impl(protocol, module)
    end
  end

  defp get_dictionary_types() do
    {:ok, modules} = :application.get_key(:definition_dictionary, :modules)

    modules
    |> Enum.filter(&String.starts_with?(to_string(&1), "Elixir.Dictionary.Type."))
    |> Enum.reject(&String.contains?(to_string(&1), "Normalizer"))
    |> Enum.reject(&String.contains?(to_string(&1), "Error"))
    |> Enum.reject(fn x -> to_string(x) =~ ~r/\.V\d+$/ end)
  end

  defp assert_impl(protocol, impl) do
    Protocol.assert_impl!(protocol, impl)
  rescue
    _e -> flunk("#{impl} does not implement the protocol #{protocol}")
  end
end
