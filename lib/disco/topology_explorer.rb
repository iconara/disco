# encoding: utf-8

require 'set'


module Disco
  class TopologyExplorer
    include EventDispatch

    def initialize(*args)
      @connection_explorer, @instances = args
    end

    def discover_topology(seed_nodes)
      exploration_queue = seed_nodes.map { |name| @instances[name] }
      exploration_queue.compact!
      topology = Set.new
      visited_instances = Set.new
      while instance = exploration_queue.pop
        next if visited_instances.include?(instance)
        trigger(:visit_instance, instance: instance)
        begin
          connections = @connection_explorer.discover_connections(instance)
          connections.each do |connection|
            exploration_queue << connection.downstream_instance
            topology << connection
          end
          visited_instances << instance
          trigger(:instance_visited, instance: instance, connections: connections)
          exploration_queue.uniq!
        rescue SocketError => e
          trigger(:connection_error, error: e, instance: instance)
        end
      end
      topology
    end
  end
end