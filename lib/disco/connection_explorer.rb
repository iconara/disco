# encoding: utf-8

require 'net/ssh'


module Disco
  class ConnectionExplorer
    def initialize(instance_cache, parser_factory, options={})
      @instance_cache = instance_cache
      @lsof_parser = parser_factory.lsof
      @netstat_parser = parser_factory.netstat
      @username = options[:username]
      @ssh_factory = options[:ssh_factory] || Net::SSH
      @sampling_duration = options[:sampling_duration] || 0.0
    end

    def discover_connections(instance, options={})
      connections = []
      @ssh_factory.start(instance.name, @username) do |session|
        stop_at = Time.now + @sampling_duration
        begin
          if output = session.exec!(LSOF_COMMAND)
            connections.concat(@lsof_parser.extract_connections(output))
          elsif output = session.exec!(NETSTAT_COMMAND)
            connections.concat(@netstat_parser.extract_connections(output))
          end
        end while Time.now < stop_at
      end
      connections.uniq!
      connections.map do |downstream, port|
        downstream_instance = @instance_cache[downstream]
        if downstream_instance && instance && downstream_instance != instance
          Connection.new(instance, downstream_instance, port)
        end
      end.compact
    end

    private

    LSOF_COMMAND = '/usr/sbin/lsof -i'.freeze
    NETSTAT_COMMAND = 'netstat --tcp --numeric'.freeze
  end
end