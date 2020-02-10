defprotocol Accept.Connection do
  @spec connect(accept :: t) :: {module, function, keyword}
  def connect(accept)
end
