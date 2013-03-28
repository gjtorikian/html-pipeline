class MockedInstrumentationService
  attr_reader :events
  def initialize(events = [])
    @events = events
  end
  def instrument(event, payload = nil)
    res = yield
    events << [event, payload, res]
    res
  end
end
