require 'disco'
require 'tmpdir'
require 'tempfile'
require 'stringio'


module StubHelpers
  def stubs(*names)
    names.each do |name|
      let(name) { stub(name) }
    end
  end
end

RSpec.configure do |conf|
  conf.extend(StubHelpers)
end
