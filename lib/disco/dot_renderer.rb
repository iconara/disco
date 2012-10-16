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

      instances = connections.flat_map do |c|
        [c.upstream_instance, c.downstream_instance] if @filter.include?(c)
      end
      instances.compact!
      instances.uniq!
      instances.sort_by!(&:name)
      instances.each do |instance|
        io.puts(sprintf(%|\t%s [label="%s"];|, node_id(instance), instance.name))
      end

      io.puts

      connections.each do |c|
        if @filter.include?(c)
          io.puts(sprintf(%|\t%s -> %s [label="%d"];|, node_id(c.upstream_instance), node_id(c.downstream_instance), c.downstream_port))
        end
      end
      io.puts('}')
    end

    private

    def node_id(instance)
      'i' << instance.private_ip_address.gsub('.', 'x')
    end
  end
end