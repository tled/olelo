require 'helper'

class Base
  extend Olelo::Factory
end

class A < Base
end

class B < Base
end

describe 'Olelo::Factory' do
  it 'should have #register' do
    Base.registry.should.be.empty
    Base.register :a, A
    Base.registry[:a].should.equal nil
    Base.registry['a'].should.equal A
    Base.register :b, B
    Base.registry['b'].should.equal B
    lambda { Base.register :a, A }.should.raise ArgumentError
  end

  it 'should have #[]' do
    Base[:a].should.equal A
    Base[:b].should.equal B
    lambda { Base[:c] }.should.raise NameError
  end
end
