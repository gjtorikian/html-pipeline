# frozen_string_literal: true

class MockedInstrumentationService
  attr_reader :events

  def initialize(event = nil, events = [])
    @events = events
    subscribe event
  end

  def instrument(event, payload = nil)
    payload ||= {}
    res = yield payload
    events << [event, payload, res] if @subscribe == event
    res
  end

  def subscribe(event)
    @subscribe = event
    @events
  end
end
