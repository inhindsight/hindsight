defmodule Accept.Udp.Socket do
  @moduledoc "TODO"

  @behaviour Accept.Socket

  @type init_opts :: [
          connection: %Accept.Udp{},
          writer: function
        ]
end
