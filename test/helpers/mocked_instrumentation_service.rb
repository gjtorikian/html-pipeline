class MockedInstrumentationService
  attr_reader :events
  def initialize(event = nil, events = [])
    @events = events
    subscribe event
  end
  def instrument(event, payload = nil)
    res = yield
    events << [event, payload, res] if @subscribe == event
    res
  end
  def subscribe(event)
    @subscribe = event
  end
end
