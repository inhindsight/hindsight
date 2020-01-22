# Properties

Asynchronously check test outcomes that are expected to
validate but may not immediately.

AssertAsync implements a macro that injects the necessary
retry logic for validating test assertions with a configurable
delay between checks and maximum number of attempted checks.

## Usage

```elixir
  defmodule Example do
    use ExUnit.Case
    import AssertAsync

    test "tests a thing" do
      do_something(args)

      assert_async do
        assert result == check_some_condition()
      end
    end
  end
```

## Installation

```elixir
def deps do
  [
    {:assert_async, in_umbrella: true}
  ]
end
```
