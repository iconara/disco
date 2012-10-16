require_relative '../spec_helper'


module Disco
  describe LsofCommand do
    stubs :session

    let :port_mapper do
      pm = stub(:port_mapper)
      pm.stub(:numeric_port) do |s|
        case s
        when 'amqp' then 5672
        else s.to_i
        end
      end
      pm
    end

    let :command do
      described_class.new(port_mapper)
    end

    let :data do
      File.readlines(__FILE__).drop_while { |line| !line.start_with?('__END') }.drop(1).join("\n")
    end

    describe '#connections' do
      let :connections do
        session.stub(:exec!).with('/usr/sbin/lsof -i').and_return(data)
        command.connections(session)
      end

      it 'returns all upstream port/downstream DNS + port triples' do
        connections.should include([43650, 'ip-10-227-121-224.eu-west-1.compute.internal', 6379])
        connections.should include([43654, 'ip-10-227-121-224.eu-west-1.compute.internal', 6379])
      end

      it 'resolves named ports' do
        connections.should include([48737, 'ip-10-48-83-190.eu-west-1.compute.internal', 5672])
      end

      it 'does not return connections to S3' do
        connections.should_not include([33447, 's3-3-w.amazonaws.com', 443])
      end
    end
  end
end

__END__
COMMAND  PID USER   FD   TYPE   DEVICE SIZE/OFF NODE NAME
java    2128 burt   32u  IPv6 73916253      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:57757->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   34u  IPv6 73916254      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:55874->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   35u  IPv6 73916255      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:45485->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   36u  IPv6 73916246      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:48737->ip-10-48-83-190.eu-west-1.compute.internal:amqp (ESTABLISHED)
java    2128 burt   37u  IPv6 73916247      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:37216->ip-10-48-178-144.eu-west-1.compute.internal:amqp (ESTABLISHED)
java    2128 burt   38u  IPv6 73916256      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:33390->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   39u  IPv6 73916257      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:44387->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   40u  IPv6 73916258      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:40337->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   41u  IPv6 73916259      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:54484->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   42u  IPv6 73916260      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:34645->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   43u  IPv6 73916261      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:58513->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   44u  IPv6 73916262      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:42693->s3-1.amazonaws.com:https (CLOSE_WAIT)
java    2128 burt   46u  IPv6 75380022      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:33447->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   47u  IPv6 75380031      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:49835->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   48u  IPv6 75379748      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43650->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   49u  IPv6 75379752      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43654->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   50u  IPv6 75379755      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43657->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   51u  IPv6 75379750      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43652->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   52u  IPv6 75380029      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:35466->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   53u  IPv6 75380030      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:34238->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   54u  IPv6 75379756      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43658->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   55u  IPv6 75380023      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:48796->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   56u  IPv6 75380028      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43595->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   60u  IPv6 75379754      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43656->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   61u  IPv6 75380033      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:47396->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   62u  IPv6 75379749      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43651->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   66u  IPv6 75379753      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43655->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   67u  IPv6 75379751      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43653->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)
java    2128 burt   68u  IPv6 75380019      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:33315->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   72u  IPv6 75380024      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:54068->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   76u  IPv6 75380032      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:48084->s3-3-w.amazonaws.com:https (ESTABLISHED)
java    2128 burt   77u  IPv6 75379744      0t0  TCP ip-10-50-71-82.eu-west-1.compute.internal:43649->ip-10-227-121-224.eu-west-1.compute.internal:6379 (ESTABLISHED)