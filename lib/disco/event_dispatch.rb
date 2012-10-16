# encoding: utf-8

module Disco
  module EventDispatch
    def on(type, &listener)
      @listeners ||= Hash.new { |h, k| h[k] = [] }
      @listeners[type] << listener
    end

    def trigger(type, event)
      if @listeners && @listeners[type]
        @listeners[type].each { |listener| listener.call(event) }
      end
    end
  end
end