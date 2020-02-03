defprotocol Accept.Connection do
  @spec connect(settings :: t) :: [{module, keyword}]
  def connect(settings)
end
