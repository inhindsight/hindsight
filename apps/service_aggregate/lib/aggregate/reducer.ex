defprotocol Aggregate.Reducer do
  @spec init(t, map) :: t
  def init(t, stats)

  @spec reduce(t, event :: term) :: t
  def reduce(t, event)

  @spec merge(t, t) :: t
  def merge(t1, t2)

  @spec to_event_fields(t) :: list({String.t(), term})
  def to_event_fields(t)
end
