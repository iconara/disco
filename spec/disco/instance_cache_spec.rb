require_relative '../spec_helper'


module Disco
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
      described_class.new(ec2, cache_path, instance_filter)
    end

    let :ec2_instances do
      [
        stub(
          :public_dns_name => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-51-34-249.eu-west-1.compute.internal',
          :private_ip_address => '10.51.34.249',
          :tags => {
            'Name' => 'stagingassembler110.byburt.com',
            'Environment' => 'staging',
            'Role' => 'assembler'
          },
          :instance_type => 'm1.large',
          :launch_time => 1347865429
        ),
        stub(
          :public_dns_name => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-227-201-65.eu-west-1.compute.internal',
          :private_ip_address => '10.227.201.65',
          :tags => {
            'Name' => 'stagingparser102.byburt.com',
            'Environment' => 'staging',
            'Role' => 'parser'
          },
          :instance_type => 'c1.xlarge',
          :launch_time => 1344843272
        )
      ]
    end

    let :cached_instances do
      [
        {
          :public_dns_name => 'ec2-54-247-63-90.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-51-34-249.eu-west-1.compute.internal',
          :private_ip_address => '10.51.34.249',
          :name => 'stagingassembler110.byburt.com',
          :environment => 'staging',
          :role => 'assembler',
          :instance_type => 'm1.large',
          :launch_time => 1347865429
        },
        {
          :public_dns_name => 'ec2-46-137-20-240.eu-west-1.compute.amazonaws.com',
          :private_dns_name => 'ip-10-227-201-65.eu-west-1.compute.internal',
          :private_ip_address => '10.227.201.65',
          :name => 'stagingparser102.byburt.com',
          :environment => 'staging',
          :role => 'parser',
          :instance_type => 'c1.xlarge',
          :launch_time => 1344843272
        }
      ]
    end

    after do
      FileUtils.rm_rf(base_dir)
    end

    def write_cache
      File.open(cache_path, 'w') do |io|
        io.write(cached_instances.to_json)
      end
    end

    context 'caching' do
      context 'when a cache exists' do
        it 'reads the cache when #resolve_name is called' do
          write_cache
          instance_cache.resolve_name('10.51.34.249').should_not be_nil
        end

        it 'reads the cache when #get is called' do
          write_cache
          instance_cache.get('10.51.34.249').should_not be_nil
        end

        it 'filters instances through the specified filter' do
          write_cache
          instance_filter.stub(:include?) { |instance| instance.role == 'parser' }
          instance_cache.get('stagingassembler110.byburt.com').should be_nil
          instance_cache.get('stagingparser102.byburt.com').should_not be_nil
        end
      end

      context 'when no cache exists' do
        it 'asks the EC2 service for all instances' do
          ec2.stub(:instances).and_return(ec2_instances)
          instance_cache.get('stagingassembler110.byburt.com')
          JSON.parse(File.read(cache_path)).should == JSON.parse(cached_instances.to_json)
        end
      end
    end

    describe '#get' do
      before do
        write_cache
      end

      it 'returns info about an instance' do
        instance_cache.get('stagingparser102.byburt.com').environment.should == 'staging'
        instance_cache.get('stagingassembler110.byburt.com').short_name.should == 'stagingassembler110'
      end
    end

    describe '#resolve_name' do
      before do
        write_cache
      end

      it 'resolves a private DNS name to a name' do
        instance_cache.resolve_name('ip-10-227-201-65.eu-west-1.compute.internal').should == 'stagingparser102.byburt.com'
      end

      it 'resolves a name to a name' do
        instance_cache.resolve_name('stagingparser102.byburt.com').should == 'stagingparser102.byburt.com'
      end

      it 'resolves a private IPv4 to a name' do
        instance_cache.resolve_name('10.51.34.249').should == 'stagingassembler110.byburt.com'
      end

      it 'resolves a private IPv6 to a name' do
        instance_cache.resolve_name('::ffff:10.51.34.249').should == 'stagingassembler110.byburt.com'
      end

      it 'returns nil if no instance matches' do
        instance_cache.resolve_name('::ffff:99.99.99.99').should be_nil
        instance_cache.resolve_name('stagingdeco101.byburt.com').should be_nil
        instance_cache.resolve_name('99.99.99.99').should be_nil
      end
    end
  end
end