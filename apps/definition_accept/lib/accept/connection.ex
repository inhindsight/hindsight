defprotocol Accept.Connection do
  @spec connect(accept :: t) :: {module, atom, keyword}
  def connect(accept)
end
