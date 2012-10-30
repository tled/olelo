require 'helper'

describe 'Object extensions' do
  it 'should have #blank?' do
    ''.should.be.blank
    {}.should.be.blank
    [].should.be.blank
    nil.should.be.blank
    'foo'.should.not.be.blank
    !{42=>'answer'}.should.not.be.blank
    [42].should.not.be.blank
    42.should.not.be.blank
  end

  it 'should have #try' do
    nil.try(:succ).should.be.nil
    1.try(:succ).should.equal 2
  end
end
