# encoding: utf-8

require 'set'


module Disco
  class TopologyExplorer
    include EventDispatch

    def initialize(*args)
      @connection_explorer, @instance_cache = args
    end

    def discover_topology(seed_nodes)
      exploration_queue = seed_nodes.map { |name| @instance_cache[name] }
      topology = Set.new
      visited_instances = Set.new
      while instance = exploration_queue.pop
        next if visited_instances.include?(instance)
        trigger(:visit_instance, instance: instance)
        connections = @connection_explorer.discover_connections(instance)
        connections.each do |connection|
          exploration_queue << connection.downstream
          topology << connection
        end
        visited_instances << instance
        trigger(:instance_visited, instance: instance, connections: connections)
        exploration_queue.uniq!
      end
      topology
    end
  end
end