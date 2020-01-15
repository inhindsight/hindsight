defmodule Properties do
  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      import Properties

      Module.put_attribute(__MODULE__, :properties_otp_app, unquote(otp_app))
    end
  end

  defmacro get_config_value(key, opts \\ []) do
    default = Keyword.get(opts, :default, nil)
    required = Keyword.get(opts, :required, false)
    module = __CALLER__.module

    case required do
      true ->
        quote do
          Application.get_env(@properties_otp_app, unquote(module), [])
          |> Keyword.fetch!(unquote(key))
        end

      false ->
        quote do
          Application.get_env(@properties_otp_app, unquote(module), [])
          |> Keyword.get(unquote(key), unquote(default))
        end
    end
  end

  defmacro getter(key, opts \\ []) do
    default = Keyword.get(opts, :default, nil)
    required = Keyword.get(opts, :required, false)
    module = __CALLER__.module

    case required do
      true ->
        quote do
          defp unquote(key)() do
            Application.get_env(@properties_otp_app, unquote(module), [])
            |> Keyword.fetch!(unquote(key))
          end
        end
      false ->
        quote do
          defp unquote(key)() do
            Application.get_env(@properties_otp_app, unquote(module), [])
            |> Keyword.get(unquote(key), unquote(default))
          end
        end
    end
  end
end
