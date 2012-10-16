# encoding: utf-8

require 'net/ssh'


module Disco
  class ConnectionExplorer
    def initialize(commands, instance_cache, options={})
      @instance_cache = instance_cache
      @commands = commands
      @username = options[:username]
      @ssh_factory = options[:ssh_factory] || Net::SSH
      @sampling_duration = options[:sampling_duration] || 0.0
    end

    def discover_connections(instance, options={})
      connections = []
      @ssh_factory.start(instance.public_dns_name, @username) do |session|
        stop_at = Time.now + @sampling_duration
        begin
          @commands.each do |command|
            c = command.connections(session)
            if c.any?
              connections.concat(c)
              break
            end
          end
        end while Time.now < stop_at
      end
      connections.uniq!
      connections.map do |upstream_port, downstream_host, downstream_port, properties|
        downstream_instance = @instance_cache[downstream_host]
        if downstream_instance && instance && downstream_instance != instance
          Connection.new(instance, downstream_instance, upstream_port, downstream_port, properties)
        end
      end.compact
    end
  end
end