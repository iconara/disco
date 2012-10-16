# encoding: utf-8

module Disco
  class DotRenderer
    def initialize(filter)
      @filter = filter
    end

    def render(connections, io=$stdout)
      io.puts("digraph {")
      io.puts("\tgraph [overlap=false];")
      io.puts("\tnode [shape=rect];")
      connections.each do |c|
        if @filter.include?(c)
          io.puts(sprintf("\t%s -> %s [label=%d];", c.upstream.name, c.downstream.name, c.port))
        end
      end
      io.puts('}')
    end
  end
end