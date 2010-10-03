require 'olelo/extensions'
require 'olelo/hooks'

describe 'Olelo::Hooks' do
  before do
    @hooks_test = Class.new do
      include Olelo::Hooks
      has_hooks :ping
      has_around_hooks :action
    end
  end

  after do
    @hooks_test = nil
  end

  it 'should check for hook existence' do
    lambda { @hooks_test.hook(:action) {} }.should.raise RuntimeError
    lambda { @hooks_test.before(:ping) {} }.should.raise RuntimeError
    lambda { @hooks_test.after(:ping) {} }.should.raise RuntimeError
    lambda { @hooks_test.new.invoke_hook(:action) {} }.should.raise RuntimeError
    lambda { @hooks_test.new.with_hooks(:ping) {} }.should.raise RuntimeError
    @hooks_test.hook(:ping) {}
    @hooks_test.before(:action) {}
    @hooks_test.after(:action) {}
    @hooks_test.new.invoke_hook(:ping)
    @hooks_test.new.with_hooks(:action) {}
  end

  it 'should provide #hook' do
    @hooks_test.should.respond_to :hook
  end

  it 'should provide #before' do
    @hooks_test.should.respond_to :before
  end

  it 'should provide #after' do
    @hooks_test.should.respond_to :after
  end

  it 'should invoke hooks' do
    hooks_test = @hooks_test
    @hooks_test.hook(:ping) do |a, b|
      self.should.be.instance_of hooks_test
      a.should.equal 1
      b.should.equal 2
      :hook1
    end
    @hooks_test.hook(:ping) do |a, b|
      :hook2
    end
    result = @hooks_test.new.invoke_hook(:ping, 1, 2)
    result.should.be.instance_of Array
    result.should.equal [:hook1, :hook2]
  end

  it 'should invoke before and after hooks' do
    hooks_test = @hooks_test
    @hooks_test.before(:action) do |a, b|
      self.should.be.instance_of hooks_test
      a.should.equal 1
      b.should.equal 2
      :action_before1
    end
    @hooks_test.before(:action) do |a, b|
      :action_before2
    end
    @hooks_test.after(:action) do |a, b|
      :action_after
    end
    result = @hooks_test.new.with_hooks(:action, 1, 2) do
      :action
    end
    result.should.be.instance_of Array
    result.should.equal [:action_before1, :action_before2, :action, :action_after]
  end

  it 'should have hook priority' do
    @hooks_test.hook(:ping, 2) { :hook1 }
    @hooks_test.hook(:ping, 1) { :hook2 }
    @hooks_test.hook(:ping, 3) { :hook3 }
    @hooks_test.new.invoke_hook(:ping).should.equal [:hook2, :hook1, :hook3]
  end
end
