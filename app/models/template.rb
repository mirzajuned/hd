require 'hashie'

class Template < Hashie::Hash
  include Hashie::Extensions::MethodAccess

  def initialize(hash = {})
    @hash = hash
  end

  def method_missing(sym, *args, &block)
    @hash[sym]
  end
end

# class MyHash

# def initialize(hash={})
#  @hash = hash
# end

# def method_missing(sym, *args, &block)
# @hash[sym]
# end

# end
