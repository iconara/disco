# encoding: utf-8

require 'aws'
require 'json'
require 'ipaddr'


module Disco
  class InstanceRegistry
    def initialize(instances)
      @instances = instances
      make_mappings
    end

    def get(name)
      @mappings[name]
    end
    alias_method :[], :get

    def find(tag_criteria)
      @instances.select do |instance|
        values = instance.tags.values_at(*tag_criteria.keys)
        values == tag_criteria.values
      end
    end

    def size
      @instances.size
    end

    private

    def make_mappings
      @mappings = {}
      @instances.each do |instance|
        @mappings[instance.name] = instance if instance.name
        @mappings[instance.id] = instance
        @mappings[instance.public_dns_name] = instance
        @mappings[instance.private_dns_name] = instance
        @mappings[instance.private_ip_address] = instance
        @mappings[IPAddr.new(instance.private_ip_address).ipv4_mapped.to_s] = instance
      end
    end
  end

  class InstanceCache
    include EventDispatch

    def initialize(*args)
      @cache_path, @ec2, @instance_filter = args
      @instance_filter ||= NullFilter.new
    end

    def instances
      cache!
      @registry
    end

    private

    def cache!
      unless @mappings
        read_cache
        unless @instances && @registry
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
        @registry = InstanceRegistry.new(@instances)
      end
    end

    def write_cache
      File.open(@cache_path, 'w') { |io| io.write(@instances.map(&:to_h).to_json) }
    end

    def find_instances
      @instances = []
      @ec2.instances.each do |instance|
        begin
          data = {
            'instance_id' => instance.instance_id,
            'public_dns_name' => instance.public_dns_name,
            'private_dns_name' => instance.private_dns_name,
            'private_ip_address' => instance.private_ip_address,
            'instance_type' => instance.instance_type,
            'launch_time' => instance.launch_time.to_i,
            'tags' => Hash[instance.tags.map { |k, v| [k, v] }]
          }
          instance = Instance.new(data)
          trigger(:instance_loaded, instance: instance)
          @instances << instance
        rescue AWS::EC2::Errors::RequestLimitExceeded => e
          trigger(:load_error, message: e.message)
          sleep(5)
          retry
        end
      end
    end
  end
end