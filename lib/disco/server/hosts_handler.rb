# encoding: utf-8

module Disco
  module Server
    class HostsHandler
      include Webbit::HttpHandler

      def initialize(instance_registry)
        @instance_registry = instance_registry
      end

      def handleHttpRequest(request, response, control)
        json = JSON.pretty_generate(@instance_registry.all.map(&:to_h))
        response.content(json).header('Content-Type', 'application/json').end
      end
    end
  end
end