# encoding: utf-8

require 'aws'
require 'json'
require 'ipaddr'


module Disco
  class InstanceCache
    def initialize(*args)
      @ec2, @cache_path, @instance_filter = args
      @instance_filter ||= NullFilter.new
    end

    def resolve_name(name)
      node = get(name)
      node.name if node
    end

    def get(name)
      cache!
      @mappings[name]
    end
    alias_method :[], :get

    private

    def cache!
      unless @mappings
        read_cache
        unless @instances
          find_instances
          write_cache
          read_cache
        end
      end
    end

    def read_cache
      if File.exists?(@cache_path)
        @instances = JSON.parse(File.read(@cache_path)).map { |data| Instance.new(data) }
        @instances = @instances.select { |instance| @instance_filter.include?(instance) }
        make_mappings
      end
    end

    def write_cache
      File.open(@cache_path, 'w') { |io| io.write(@instances.map(&:to_h).to_json) }
    end

    def make_mappings
      @mappings = {}
      @instances.each do |instance|
        @mappings[instance.name] = instance
        @mappings[instance.private_dns_name] = instance
        @mappings[instance.private_ip_address] = instance
        @mappings[IPAddr.new(instance.private_ip_address).ipv4_mapped.to_s] = instance
      end
    end

    def find_instances
      @instances = []
      @ec2.instances.each do |instance|
        begin
          data = {
            :public_dns_name => instance.public_dns_name,
            :private_dns_name => instance.private_dns_name,
            :private_ip_address => instance.private_ip_address,
            :instance_type => instance.instance_type,
            :launch_time => instance.launch_time.to_i
          }
          instance.tags.each do |k, v|
            data[k.downcase.to_sym] = v
          end
          @instances << Instance.new(data)
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          sleep(5)
          retry
        end
      end
    end
  end
end