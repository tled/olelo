require 'olelo/virtualfs'
require 'olelo/templates'
require 'slim'

class Bacon::Context
  include Olelo::Templates
end

class TestTemplateLoader
  def context
    nil
  end

  def load(path)
    Olelo::VirtualFS::Embedded.new(__FILE__).read(path)
  end
end

describe 'Olelo::Templates' do
  before do
    Olelo::Templates.enable_caching
    Olelo::Templates.loader = TestTemplateLoader.new
  end

  after do
    Olelo::Templates.cache.clear
  end

  it 'should have #render' do
    render(:test, :locals => {:text => 'Hello, World!'}).should.equal "<h1>Hello, World!</h1>"
    Olelo::Templates.cache.size.should.equal 1
  end
end

__END__

@@ test.slim  
h1= text

