require_relative '../spec_helper'


module Disco
  describe ConnectionExplorer do
    stubs :ssh_factory, :ssh_session, :lsof_parser, :netstat_parser

    let :parser_factory do
      stub(:parser_factory, lsof: lsof_parser, netstat: netstat_parser)
    end

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
      described_class.new(instance_cache, parser_factory, ssh_factory: ssh_factory, username: 'phil')
    end

    let :multisampling_explorer do
      described_class.new(instance_cache, parser_factory, ssh_factory: ssh_factory, username: 'phil', sampling_duration: 0.01)
    end

    describe '#discover_connections' do
      before do
        ssh_factory.stub(:start).with('host1', 'phil').and_yield(ssh_session)
        ssh_session.stub(:exec!).with('/usr/sbin/lsof -i').and_return('LSOFOUT1', 'LSOFOUT2', 'LSOFOUT3')
        lsof_parser.stub(:extract_connections).with('LSOFOUT1').and_return([['host2', 1]])
        lsof_parser.stub(:extract_connections).with('LSOFOUT2').and_return([['host2', 11]])
        lsof_parser.stub(:extract_connections).with('LSOFOUT3').and_return([['host2', 11], ['host2', 111]])
        netstat_parser.stub(:extract_connections).with('NETSTATOUT').and_return([['host2', 2]])
      end

      it 'connects to the host and runs lsof' do
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'runs netstat if lsof produces no results' do
        ssh_session.stub(:exec!).with('/usr/sbin/lsof -i').and_return(nil)
        ssh_session.stub(:exec!).with('netstat --tcp --numeric').and_return('NETSTATOUT')
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 2)]
      end

      it 'returns an empty list if neither lsof or netstat produces any results' do
        ssh_session.stub(:exec!).with('/usr/sbin/lsof -i').and_return(nil)
        ssh_session.stub(:exec!).with('netstat --tcp --numeric').and_return(nil)
        explorer.discover_connections(instance1).should == []
      end

      it 'does not return anything for hosts not in the instance cache' do
        lsof_parser.stub(:extract_connections).with('LSOFOUT1').and_return([['host2', 1], ['host3', 1]])
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'does not return connections to the same host' do
        lsof_parser.stub(:extract_connections).with('LSOFOUT1').and_return([['host2', 1], ['host1', 1]])
        explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1)]
      end

      it 'runs the command multiple times' do
        multisampling_explorer.discover_connections(instance1).should == [Connection.new(instance1, instance2, 1), Connection.new(instance1, instance2, 11), Connection.new(instance1, instance2, 111)]
      end
    end
  end
end
