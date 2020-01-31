defprotocol Acquire.Queryable do
  # TODO
  @moduledoc false

	@spec parse_statement(t) :: String.t()
  def parse_statement(query)

  @spec parse_input(t) :: [term]
  def parse_input(query)
end
