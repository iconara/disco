# encoding: utf-8

module Disco
  class Connection
    attr_reader :upstream, :downstream, :port

    def initialize(*args)
      @upstream, @downstream, @port = args
    end

    def eql?(other)
      self.upstream == other.upstream && self.downstream == other.downstream && self.port == other.port
    end
    alias_method :==, :eql?

    def hash
      @hash ||= (((upstream.hash * 31) ^ (downstream.hash)) * 31) ^ port
    end

    def to_s
      @s ||= "Connection(#{upstream}, #{downstream}, #{port})"
    end
  end
end