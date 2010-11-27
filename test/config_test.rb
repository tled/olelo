require 'helper'

describe 'Olelo::Config' do
  it 'should have #[]= and #[]' do
    config = Olelo::Config.new
    config['a.b.c'] = 42
    config['a.b.c'].should.equal 42
    config['a.b']['c'].should.equal 42
    config['a']['b']['c'].should.equal 42
  end

  it 'should be enumerable' do
    config = Olelo::Config.new
    config['a.x.y'] = 42
    config['b.x.y'] = 43
    config.each do |key, child|
      key.should.be.instance_of String
      child.should.be.instance_of Olelo::Config
      child['x.y'].should.be.instance_of Fixnum
    end
  end

  it 'should raise NameError' do
    lambda do
      Olelo::Config.new.not.existing
    end.should.raise NameError
  end
end
