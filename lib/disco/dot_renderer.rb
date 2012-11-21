# encoding: utf-8

require 'set'
require 'color-generator'


module Disco
  class DotRenderer
    include RendererUtils

    def initialize(*args)
      @filter, @colorizer = args
      @colorizer ||= NullColorizer.new
    end

    def render(connections, io=$stdout)
      io.puts(%|digraph "Topology" {|)
      io.puts(%|\tgraph [overlap=false];|)
      io.puts(%|\tnode [shape="rect", fontname="Helvetica", style="filled"];|)
      io.puts(%|\tedge [fontname="Helvetica"];|)
      io.puts
      print_nodes(uniq_instances(connections), io)
      print_edges(connections, io)
      io.puts('}')
    end

    private

    def print_nodes(instances, io)
      instances.each do |instance|
        label_color, fill_color = @colorizer.colors(instance)
        io.puts(sprintf(%|\t%s [label="%s", fontcolor="%s", fillcolor="%s"];|, node_id(instance), instance.name, label_color, fill_color))
      end
      io.puts
    end

    def print_edges(connections, io)
      deduplicate_connections(connections).each do |c|
        if @filter.include?(c)
          upstream = node_id(c.upstream_instance)
          downstream = node_id(c.downstream_instance)
          port = c.downstream_port
          io.puts(sprintf(%|\t%s -> %s [label="%d"];|, upstream, downstream, port))
        end
      end
    end
  end

  class NullColorizer
    def colors(instance)
      ['black', 'transparent']
    end
  end

  class TagColorizer
    def initialize(tag)
      generator = ColorGenerator.new(saturation: 0.5, lightness: 0.3)
      @tag = tag
      @colors = Hash.new do |h, k|
        h[k] = '#' << generator.create
      end
    end

    def colors(instance)
      ['white', @colors[instance.tags[@tag]]]
    end
  end
end