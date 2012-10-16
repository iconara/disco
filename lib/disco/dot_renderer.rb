# encoding: utf-8

module Disco
  class DotRenderer
    def initialize(filter)
      @filter = filter
    end

    def render(connections, io=$stdout)
      io.puts("digraph topology {")
      io.puts("\tgraph [overlap=false];")
      io.puts("\tnode [shape=rect];")
      io.puts
      print_nodes(uniq_instances(connections), io)
      print_edges(connections, io)
      io.puts('}')
    end

    private

    def uniq_instances(connections)
      instances = connections.flat_map do |c|
        [c.upstream_instance, c.downstream_instance] if @filter.include?(c)
      end
      instances.compact!
      instances.uniq!
      instances.sort_by!(&:name)
    end

    def print_nodes(instances, io)
      instances.each do |instance|
        io.puts(sprintf(%|\t%s [label="%s"];|, node_id(instance), instance.name))
      end
      io.puts
    end

    def print_edges(connections, io)
      printed_edges = Set.new
      connections.each do |c|
        if @filter.include?(c)
          edge = sprintf(%|\t%s -> %s [label="%d"];|, node_id(c.upstream_instance), node_id(c.downstream_instance), c.downstream_port)
          unless printed_edges.include?(edge)
            io.puts(edge)
            printed_edges << edge
          end
        end
      end
    end

    def node_id(instance)
      'i' << instance.private_ip_address.gsub('.', 'x')
    end
  end
end