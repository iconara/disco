# encoding: utf-8

module Disco
  class DotRenderer
    def initialize(service_mappings)
      @service_mappings = service_mappings
    end

    def render(connections, io=$stdout)
      io.puts("digraph {")
      io.puts("\tgraph [overlap=false];")
      io.puts("\tnode [shape=rect];")
      connections.each do |c|
        prefix = @service_mappings.service?(c.port) ? '' : '#'
        io.puts(sprintf("%s\t%s -> %s [label=%d];", prefix, c.upstream.short_name, c.downstream.short_name, c.port))
      end
      io.puts('}')
    end
  end
end