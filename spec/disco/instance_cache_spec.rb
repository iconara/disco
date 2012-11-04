require_relative '../spec_helper'


module Disco
  describe InstanceRegistry do
    let :instances do
      [
        Instance.new(
          'instance_id' => 'i-f379e599',
          'public_dns_name' => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-51-34-249.eu-west-1.compute.internal',
          'private_ip_address' => '10.51.34.249',
          'instance_type' => 'm1.large',
          'launch_time' => 1347865429,
          'availability_zone' => 'eu-west-1a',
          'tags' => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          }
        ),
        Instance.new(
          'instance_id' => 'i-a79e67b09',
          'public_dns_name' => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-227-201-65.eu-west-1.compute.internal',
          'private_ip_address' => '10.227.201.65',
          'instance_type' => 'c1.xlarge',
          'launch_time' => 1344843272,
          'availability_zone' => 'eu-west-1b',
          'tags' => {
            'Name' => 'p1.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          }
        )
      ]
    end

    let :registry do
      described_class.new(instances)
    end

    describe '#get' do
      it 'finds instances by ID' do
        registry.get('i-a79e67b09').should == instances[1]
      end

      it 'finds instances by internal DNS name' do
        registry.get('ip-10-227-201-65.eu-west-1.compute.internal').should == instances[1]
      end

      it 'finds instances by public DNS name' do
        registry.get('ec2-54-247-63-90.eu-west-1.compute.amazonaws.com').should == instances[0]
      end

      it 'finds instances by the "Name" tag' do
        registry.get('p1.example.com').should == instances[1]
      end

      it 'finds instances by IPv4 address' do
        registry.get('10.51.34.249').should == instances[0]
      end

      it 'finds instances by IPv6 address' do
        registry.get('::ffff:10.51.34.249').should == instances[0]
      end

      it 'returns nil when nothing is found' do
        registry.get('::ffff:99.99.99.99').should be_nil
        registry.get('example.com').should be_nil
        registry.get('99.99.99.99').should be_nil
      end

      it 'is an alias for #[]' do
        registry['::ffff:10.51.34.249'].should == instances[0]
      end
    end

    describe '#find' do
      before do
        tags1 = {'Name' => 's1.example.com', 'Environment' => 'staging', 'Role' => 'web'}
        tags2 = {'Name' => 'p3.example.com', 'Environment' => 'production', 'Role' => 'web'}
        tags3 = {'Name' => 'p4.example.com', 'Environment' => 'production', 'Role' => 'db'}
        instances << Instance.new(instances[1].to_h.merge('tags' => tags1))
        instances << Instance.new(instances[1].to_h.merge('tags' => tags2))
        instances << Instance.new(instances[1].to_h.merge('tags' => tags3))
      end

      it 'finds instances by tag' do
        registry.find('Name' => 'p1.example.com').should == [instances[1]]
      end

      it 'finds instances by multiple tags' do
        registry.find('Role' => 'web', 'Environment' => 'production').should == [instances[1], instances[3]]
      end
    end
  end

  describe InstanceCache do
    stubs :ec2

    let :base_dir do
      Dir.mktmpdir('disco')
    end

    let :cache_path do
      File.join(base_dir, 'instances.json')
    end

    let :instance_filter do
      stub(:instance_filter, :include? => true)
    end

    let :instance_cache do
      described_class.new(cache_path, ec2, instance_filter)
    end

    let :ec2_instance_data do
      [
        stub(
          :instance_id => 'i-f379e599',
          :public_dns_name => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-51-34-249.eu-west-1.compute.internal',
          :private_ip_address => '10.51.34.249',
          :tags => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          },
          :instance_type => 'm1.large',
          :launch_time => 1347865429,
          :availability_zone => 'eu-west-1a'
        ),
        stub(
          :instance_id => 'i-a79e67b09',
          :public_dns_name => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-227-201-65.eu-west-1.compute.internal',
          :private_ip_address => '10.227.201.65',
          :tags => {
            'Name' => 'p1.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          },
          :instance_type => 'c1.xlarge',
          :launch_time => 1344843272,
          :availability_zone => 'eu-west-1a'
        ),
        stub(
          :instance_id => 'i-8b675d45',
          :public_dns_name => 'ec2-52-110-25-1.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-32-153-4.eu-west-1.compute.internal',
          :private_ip_address => '10.32.153.4',
          :tags => {
            'Name' => 'p2.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          },
          :instance_type => 'c1.xlarge',
          :launch_time => 1344888950,
          :availability_zone => 'eu-west-1b'
        )
      ]
    end

    let :cached_data do
      [
        {
          'instance_id' => 'i-f379e599',
          'public_dns_name' => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-51-34-249.eu-west-1.compute.internal',
          'private_ip_address' => '10.51.34.249',
          'instance_type' => 'm1.large',
          'launch_time' => 1347865429,
          'tags' => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          },
          'availability_zone' => 'eu-west-1a'
        },
        {
          'instance_id' => 'i-a79e67b09',
          'public_dns_name' => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-227-201-65.eu-west-1.compute.internal',
          'private_ip_address' => '10.227.201.65',
          'instance_type' => 'c1.xlarge',
          'launch_time' => 1344843272,
          'tags' => {
            'Name' => 'p1.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          },
          'availability_zone' => 'eu-west-1a'
        }
      ]
    end

    after do
      FileUtils.rm_rf(base_dir)
    end

    def write_cache
      File.open(cache_path, 'w') do |io|
        io.write(cached_data.to_json)
      end
    end

    describe '#instances' do
      context 'when a cache exists' do
        it 'returns an instance registry with the cached instances' do
          write_cache
          instance_cache.instances['i-f379e599'].should == Instance.new(cached_data[0])
        end

        it 'filters instances through the specified filter' do
          write_cache
          instance_filter.stub(:include?) { |instance| instance.instance_type == 'm1.large' }
          instance_cache.instances['i-f379e599'].should_not be_nil
          instance_cache.instances['i-a79e67b09'].should be_nil
        end
      end

      context 'when no cache exists' do
        before do
          ec2_instance_data.reduce(ec2.stub(:each_instance)) do |stub, instance|
            stub.and_yield(instance)
          end
        end

        it 'asks the EC2 service for all instances' do
          instance_cache.instances.should have(3).items
        end

        it 'saves the right properties' do
          instance = instance_cache.instances['i-8b675d45']
          instance.id.should == 'i-8b675d45'
          instance.public_dns_name.should == 'ec2-52-110-25-1.eu-west-1.compute.amazonaws.com'
          instance.private_dns_name.should == 'ip-10-32-153-4.eu-west-1.compute.internal'
          instance.private_ip_address.should == '10.32.153.4'
          instance.tags.should == {'Name' => 'p2.example.com', 'Environment' => 'production', 'Role' => 'web'}
          instance.instance_type.should == 'c1.xlarge'
          instance.launch_time.should == 1344888950
          instance.availability_zone.should == 'eu-west-1b'
        end

        it 'writes the instances to the cache file' do
          instance_cache.instances
          JSON.parse(File.read(cache_path)).should have(3).items
        end

        it 'dispatches an event when looking up an instance' do
          triggered = false
          instance_cache.on(:instance_loaded) { |e| triggered = true }
          expect { instance_cache.instances }.to change { triggered }.to(true)
        end
      end
    end
  end
end