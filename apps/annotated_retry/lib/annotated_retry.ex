defmodule Annotated.Retry do
  defmacro __using__(_opts) do
    quote do
      import Retry.DelayStreams
      import Stream, only: [take: 2]
      require Retry

      Module.register_attribute(__MODULE__, :retry_funs, accumulate: true)

      @on_definition {Annotated.Retry, :on_def}
      @before_compile {Annotated.Retry, :before_compile}
    end
  end

  def on_def(env, kind, name, args, guards, _body) do
    retry_opts = Module.get_attribute(env.module, :retry, :no_retry)

    unless retry_opts == :no_retry do
      Module.put_attribute(env.module, :retry_funs, %{
        kind: kind,
        name: name,
        args: args,
        guards: guards,
        retry_opts: Keyword.update(retry_opts, :with, [], &Enum.to_list/1)
      })

      Module.delete_attribute(env.module, :retry)
    end
  end

  defmacro before_compile(env) do
    retry_funs = Module.get_attribute(env.module, :retry_funs, [])
    Module.delete_attribute(env.module, :retry_funs)

    override_list =
      Enum.map(retry_funs, fn %{name: name, args: args} ->
        {name, length(args)}
      end)

    overrides =
      quote do
        defoverridable unquote(override_list)
      end

    functions =
      Enum.map(retry_funs, fn fun ->
        body = gen_body(fun)
        gen_function(fun, body)
      end)

    [overrides | functions]
  end

  defp gen_function(%{kind: :def, guards: [], name: name, args: args}, body) do
    quote do
      def unquote(name)(unquote_splicing(args)) do
        unquote(body)
      end
    end
  end

  defp gen_function(%{kind: :def, guards: guards, name: name, args: args}, body) do
    quote do
      def unquote(name)(unquote_splicing(args)) when unquote_splicing(guards) do
        unquote(body)
      end
    end
  end

  defp gen_function(%{kind: :defp, guards: [], name: name, args: args}, body) do
    quote do
      defp unquote(name)(unquote_splicing(args)) do
        unquote(body)
      end
    end
  end

  defp gen_function(%{kind: :defp, guards: guards, name: name, args: args}, body) do
    quote do
      defp unquote(name)(unquote_splicing(args)) when unquote_splicing(guards) do
        unquote(body)
      end
    end
  end

  defp gen_body(fun) do
    quote do
      Retry.retry_while unquote(fun.retry_opts) do
        case super(unquote_splicing(fun.args)) do
          {:error, _} = error -> {:cont, error}
          result -> {:halt, result}
        end
      end
    end
  end
end
