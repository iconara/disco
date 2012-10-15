require_relative '../spec_helper'


module Disco
  describe ConnectionExplorer do
    stubs :ssh_factory, :ssh_session, :command1, :command2

    let :instance1 do
      stub(:instance1, :name => 'host1')
    end

    let :instance2 do
      stub(:instance2, :name => 'host2')
    end

    let :instance_cache do
      ic = stub(:instance_cache)
      ic.stub(:[]).with('host1').and_return(instance1)
      ic.stub(:[]).with('host2').and_return(instance2)
      ic.stub(:[]).with('host3').and_return(nil)
      ic
    end

    let :explorer do
      described_class.new([command1, command2], instance_cache, ssh_factory: ssh_factory, username: 'phil')
    end

    let :multisampling_explorer do
      described_class.new([command1, command2], instance_cache, ssh_factory: ssh_factory, username: 'phil', sampling_duration: 0.01)
    end

    describe '#discover_connections' do
      before do
        ssh_factory.stub(:start).with('host1', 'phil').and_yield(ssh_session)
        command1.stub(:connections).with(ssh_session).and_return([['host2', 1]], [['host2', 11]], [['host2', 111]])
        command2.stub(:connections).with(ssh_session).and_return([['host2', 2]])
      end

      it 'connects to the host and runs a command' do
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'runs the second command if the first gives an empty list' do
        command1.stub(:connections).and_return([])
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 2)]
      end

      it 'returns an empty list if neither command produces any results' do
        command1.stub(:connections).and_return([])
        command2.stub(:connections).and_return([])
        explorer.discover_connections(instance1).should == []
      end

      it 'does not return anything for hosts not in the instance cache' do
        command1.stub(:connections).with(ssh_session).and_return([['host2', 1], ['host3', 1]])
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'does not return connections to the same host' do
        command1.stub(:connections).with(ssh_session).and_return([['host2', 1], ['host1', 1]])
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'runs the command multiple times' do
        multisampling_explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1), Connection.new(instance1, instance2, 11), Connection.new(instance1, instance2, 111)]
      end
    end
  end
end
