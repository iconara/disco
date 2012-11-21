# encoding: utf-8

module Disco
  module RendererUtils
    def uniq_instances(connections)
      instances = connections.flat_map do |c|
        [c.upstream_instance, c.downstream_instance]
      end
      instances.compact!
      instances.uniq!
      instances.sort_by!(&:name)
    end

    def node_id(instance)
      instance.id.sub('-', '')
    end

    def deduplicate_connections(connections)
      cs = connections.group_by { |connection| Set.new([connection.upstream_instance, connection.downstream_instance]) }
      cs.map do |_, connections|
        if connections.all? { |c| normalized_speed(c.properties['send']) == 0.0 }
          connections.sort_by { |c| c.downstream_port }.first
        else
          connections.sort_by { |c| normalized_speed(c.properties['send']) }.last
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
end