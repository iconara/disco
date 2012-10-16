require_relative '../spec_helper'


module Disco
  describe Connection do
    let :instance0 do
      stub(:instance0, :name => 'host0', :private_ip_address => '0.0.0.0')
    end

    let :instance1 do
      stub(:instance1, :name => 'host1', :private_ip_address => '1.1.1.1')
    end

    let :connection do
      described_class.new(instance0, instance1, 1, 2)
    end

    describe '#to_h' do
      it 'returns a basic hash with instance name in place of instance' do
        connection.to_h.should == {
          :upstream_host => 'host0',
          :downstream_host => 'host1',
          :upstream_port => 1,
          :downstream_port => 2,
          :properties => {}
        }
      end

      it 'uses private IP if name is nil' do
        instance1.stub(:name).and_return(nil)
        connection.to_h.should == {
          :upstream_host => 'host0',
          :downstream_host => '1.1.1.1',
          :upstream_port => 1,
          :downstream_port => 2,
          :properties => {}
        }
      end
    end

    describe '.from_h' do
      let :instances do
        i = stub(:instances)
        i.stub(:[]).with('host0').and_return(instance0)
        i.stub(:[]).with('host1').and_return(instance1)
        i
      end

      let :hash_string_keys do
        {
          'upstream_host' => 'host0',
          'downstream_host' => 'host1',
          'upstream_port' => 1,
          'downstream_port' => 2,
          'properties' => {'test' => 123}
        }
      end

      let :hash_symbol_keys do
        {
          :upstream_host => 'host0',
          :downstream_host => 'host1',
          :upstream_port => 1,
          :downstream_port => 2,
          :properties => {'test' => 123}
        }
      end

      it 'creates an instance from the given properties (with symbol keys), resolving instances with the instance registry' do
        connection = Connection.from_h(hash_symbol_keys, instances)
        connection.upstream_instance.should == instance0
        connection.downstream_instance.should == instance1
        connection.upstream_port.should == 1
        connection.downstream_port.should == 2
        connection.properties.should == {'test' => 123}
      end

      it 'creates an instance from the given properties (with string keys), resolving instances with the instance registry' do
        connection = described_class.from_h(hash_string_keys, instances)
        connection.upstream_instance.should == instance0
        connection.downstream_instance.should == instance1
        connection.upstream_port.should == 1
        connection.downstream_port.should == 2
        connection.properties.should == {'test' => 123}
      end

      it 'raises an error if an instance could not be resolved' do
        instances.stub(:[]).with('host1').and_return(nil)
        expect { described_class.from_h(hash_string_keys, instances) }.to raise_error(ArgumentError)
      end
    end

    describe '#eql?' do
      it 'is equal to itself' do
        connection.eql?(connection).should be_true
      end

      it 'is equal to a connection with the same upstream and downstream instances and ports' do
        connection.eql?(described_class.new(instance0, instance1, 1, 2)).should be_true
      end

      it 'is not equal if the ports differ' do
        connection.eql?(described_class.new(instance0, instance1, 2, 1)).should be_false
      end

      it 'is not equal if the instances are reversed' do
        connection.eql?(described_class.new(instance1, instance0, 1, 2)).should be_false
      end

      it 'is equal even if the properties differ' do
        connection.eql?(described_class.new(instance0, instance1, 1, 2, {'test' => 999})).should be_true
      end
    end

    describe '#hash' do
      it 'is the same for the same the same upstream and downstream instances and ports' do
        connection.hash.should == described_class.new(instance0, instance1, 1, 2).hash
      end

      it 'is different if the ports differ' do
        connection.hash.should_not == described_class.new(instance0, instance1, 99, 2).hash
      end

      it 'is different if the instances are reversed' do
        connection.hash.should_not == described_class.new(instance1, instance0, 1, 2).hash
      end

      it 'is the same even if the properties differ' do
        connection.hash.should == described_class.new(instance0, instance1, 1, 2, {'test' => 'hello'}).hash
      end
    end
  end
end