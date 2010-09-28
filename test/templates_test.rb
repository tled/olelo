require 'olelo/virtualfs'
require 'olelo/templates'
require 'haml'

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
    render(:test, :locals => {:text => 'Hello, World!'}).should.equal "<h1>Hello, World!</h1>\n"
    Olelo::Templates.cache.size.should.equal 1
  end

  it 'should support haml options' do
    render(:test, :escape_html => false, :locals => {:text => '< bad characters >'}).should.equal "<h1>< bad characters ></h1>\n"
    render(:test, :locals => {:text => '< bad characters >'}).should.equal "<h1>&lt; bad characters &gt;</h1>\n"
  end
end

__END__

@@ test.haml  
%h1= text

