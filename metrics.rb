require "socket"
require "json"

module Metrics
  extend self

  def event(type, data={})
    socket = UDPSocket.new
    payload = JSON.dump(data.merge(_type: type))
    puts payload
    socket.send(payload, 0, FNM_HOST, FNM_PORT)
  end

  def time(type, data={}, &block)
    start = Time.now.to_f
    yield
    time = Time.now.to_f - start
    self.event(type, data.merge(time: time))
  end
end
