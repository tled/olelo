require 'helper'

describe 'Hash extensions' do
  it 'should have #with_indifferent_access' do
    {}.with_indifferent_access.should.equal Hash.with_indifferent_access

    hash = Hash.with_indifferent_access
    hash[:a] = 10
    hash['a'].should.equal 10
    hash[:a].should.equal 10
    hash.include?(:a).should.be.true
    hash.include?('a').should.be.true
    hash.include?(:b).should.be.false
    hash.keys.should.equal %w(a)
  end
end
