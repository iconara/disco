require_relative '../spec_helper'


module Disco
  describe ServicePortMapper do
    let :services_path do
      t = Tempfile.new('services')
      t.puts(File.readlines(__FILE__).drop_while { |line| line.start_with?('__END') }.drop(1).join("\n"))
      t.close
      t.path
    end

    let :mapper do
      described_class.new(:path => services_path, :custom => {'test' => 1234}, :significant => [1..10_000, 27017])
    end

    describe '#numeric_port' do
      it 'maps a service name to a port number' do
        mapper.numeric_port('blp5').should == 48129
      end

      it 'maps a numeric argument to itself' do
        mapper.numeric_port('9999').should == 9999
      end

      it 'maps custom services to a port number' do
        mapper.numeric_port('test').should == 1234
      end

      it 'returns nil if nothing is found' do
        mapper.numeric_port('apa').should be_nil
      end
    end
  end
end

__END__
isnetserv       48128/tcp   # Image Systems Network Services
isnetserv       48128/udp   # Image Systems Network Services
blp5            48129/tcp   # Bloomberg locator
blp5            48129/udp   # Bloomberg locator
#               48130-48555 Unassigned
com-bardac-dw   48556/udp    # com-bardac-dw
com-bardac-dw   48556/tcp    # com-bardac-dw
#                           Nicholas J Howes <nick@ghostwood.org>
#               48557-49150 Unassigned 
#               49151       IANA Reserved
