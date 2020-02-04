defprotocol Accept.Connection do
  @spec connect(settings :: t) :: keyword
  def connect(settings)
end
