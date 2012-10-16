# encoding: utf-8

require 'set'
require 'color-generator'


module Disco
  class DotRenderer
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

    def uniq_instances(connections)
      instances = connections.flat_map do |c|
        [c.upstream_instance, c.downstream_instance]
      end
      instances.compact!
      instances.uniq!
      instances.sort_by!(&:name)
    end

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

    def node_id(instance)
      instance.id.sub('-', '')
    end

    def deduplicate_connections(connections)
      cs = connections.group_by { |connection| Set.new([connection.upstream_instance, connection.downstream_instance]) }
      cs.map do |_, connections|
        if connections.all? { |c| normalized_speed(c.properties['speed']) == 0.0 }
          connections.sort_by { |c| c.downstream_port }.first
        else
          connections.sort_by { |c| normalized_speed(c.properties['speed']) }.last
        end
      end
    end

    def normalized_speed(speed_str)
      return 0.0 unless speed_str
      speed, unit = speed_str.scan(/^([\d.]+)(\w)bps$/).flatten
      speed = speed.to_f
      case unit
      when 'M' then speed * 1024 * 1024
      when 'K' then speed * 1024
      else speed
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