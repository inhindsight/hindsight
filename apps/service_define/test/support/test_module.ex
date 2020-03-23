defmodule TestModule do
  defstruct integer_type: nil,
            string_type: nil,
            atom_type: nil,
            float_type: nil,
            string_list_type: nil,
            integer_list_type: nil,
            map_type: nil

  @type t :: %__MODULE__{
          integer_type: integer(),
          string_type: String.t(),
          atom_type: atom(),
          float_type: float(),
          string_list_type: list(String.t()),
          integer_list_type: list(integer()),
          map_type: map()
        }
end
