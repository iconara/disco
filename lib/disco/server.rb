# encoding: utf-8

require 'webbit'
require 'disco/server/events_handler'
require 'disco/server/explorer_control_handler'
require 'disco/server/hosts_handler'


module Disco
  module Server
    module JavaConcurrent
      include_package 'java.util.concurrent'
    end

    def self.start(instance_registry, topology_explorer, port=3000)
      executor = JavaConcurrent::Executors.new_cached_thread_pool

      hosts_handler = HostsHandler.new(instance_registry)
      events_handler = EventsHandler.new(topology_explorer)
      explorer_control_handler = ExplorerControlHandler.new(topology_explorer, executor)

      Webbit.start_server(port) do
        map '/hosts' => hosts_handler
        map '/events' => events_handler
        map %r'^/disco/.+' => explorer_control_handler
        map :static => 'public'
      end
    end
  end

  class Disco
    def server(port=3000)
      Server.start(instance_registry, topology_explorer, port)
    end
  end
end