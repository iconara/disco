require_relative '../spec_helper'


module Disco
  describe Instance do
    let :instance do
      Instance.new(
        'instance_id' => 'i-4b657e12',
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
      )
    end

    describe '#name' do
      it 'returns the value of the "Name" tag' do
        instance.name.should == 's1.example.com'
      end

      it 'is nil if there is no "Name" tag' do
        Instance.new(instance.to_h.merge('tags' => {})).name.should be_nil
      end
    end

    describe '#eql?' do
      it 'is equal to itself' do
        instance.eql?(instance).should be_true
      end

      it 'is equal to an identical instance' do
        instance.eql?(Instance.new(instance.to_h)).should be_true
      end

      it 'is not equal to a different instance' do
        overrides = {
          'instance_id' => 'i-234b123c',
          'instance_type' => 'c1.xlarge',
          'private_ip_address' => '10.251.12.4'
        }
        instance.eql?(Instance.new(instance.to_h.merge(overrides))).should be_false
      end

      it 'is equal to a different instance with the same instance ID' do
        overrides = {
          'instance_type' => 'c1.xlarge',
          'public_dns_name' => 'ec2-76-212-10-4.eu-west-1.compute.amazonaws.com',
        }
        instance.eql?(Instance.new(instance.to_h.merge(overrides))).should be_true
      end
    end
  end
end