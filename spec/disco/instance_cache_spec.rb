require_relative '../spec_helper'


module Disco
  describe InstanceRegistry do
    let :instances do
      [
        Instance.new(
          'public_dns_name' => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-51-34-249.eu-west-1.compute.internal',
          'private_ip_address' => '10.51.34.249',
          'instance_type' => 'm1.large',
          'launch_time' => 1347865429,
          'tags' => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          }
        ),
        Instance.new(
          'public_dns_name' => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-227-201-65.eu-west-1.compute.internal',
          'private_ip_address' => '10.227.201.65',
          'instance_type' => 'c1.xlarge',
          'launch_time' => 1344843272,
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
        instances << Instance.new(instances[1].to_h.merge('private_ip_address' => '99.99.99.99', 'tags' => tags1))
        instances << Instance.new(instances[1].to_h.merge('private_ip_address' => '88.88.88.88', 'tags' => tags2))
        instances << Instance.new(instances[1].to_h.merge('private_ip_address' => '77.77.77.77', 'tags' => tags3))
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
          :public_dns_name => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-51-34-249.eu-west-1.compute.internal',
          :private_ip_address => '10.51.34.249',
          :tags => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          },
          :instance_type => 'm1.large',
          :launch_time => 1347865429
        ),
        stub(
          :public_dns_name => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-227-201-65.eu-west-1.compute.internal',
          :private_ip_address => '10.227.201.65',
          :tags => {
            'Name' => 'p1.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          },
          :instance_type => 'c1.xlarge',
          :launch_time => 1344843272
        ),
        stub(
          :public_dns_name => 'ec2-52-110-25-1.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-32-153-4.eu-west-1.compute.internal',
          :private_ip_address => '10.32.153.4',
          :tags => {
            'Name' => 'p2.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          },
          :instance_type => 'c1.xlarge',
          :launch_time => 1344888950
        )
      ]
    end

    let :cached_data do
      [
        {
          'public_dns_name' => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-51-34-249.eu-west-1.compute.internal',
          'private_ip_address' => '10.51.34.249',
          'instance_type' => 'm1.large',
          'launch_time' => 1347865429,
          'tags' => {
            'Name' => 's1.example.com',
            'Environment' => 'staging',
            'Role' => 'cruncher'
          }
        },
        {
          'public_dns_name' => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          'private_dns_name' => 'ip-10-227-201-65.eu-west-1.compute.internal',
          'private_ip_address' => '10.227.201.65',
          'instance_type' => 'c1.xlarge',
          'launch_time' => 1344843272,
          'tags' => {
            'Name' => 'p1.example.com',
            'Environment' => 'production',
            'Role' => 'web'
          }
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
          instance_cache.instances['10.51.34.249'].should == Instance.new(cached_data[0])
        end

        it 'filters instances through the specified filter' do
          write_cache
          instance_filter.stub(:include?) { |instance| instance.instance_type == 'm1.large' }
          instance_cache.instances['10.51.34.249'].should_not be_nil
          instance_cache.instances['10.227.201.65'].should be_nil
        end
      end

      context 'when no cache exists' do
        before do
          ec2.stub(:instances).and_return(ec2_instance_data)
        end

        it 'asks the EC2 service for all instances' do
          instance_cache.instances.should have(3).items
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