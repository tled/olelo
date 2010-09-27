description  'Math tag for LaTeX rendering'
dependencies 'filter/tag'

class Olelo::MathRenderer
  include Util

  def initialize
    @loaded = false
  end

  def init
    @loaded ||= load rescue false
  end

  def load
    true
  end

  class << self
    attr_accessor :registry

    def get_first(renderers)
      renderers.each do |r|
        r = get(r)
        return r if r
      end
    end

    def get(name)
      renderer = registry[name] || raise("Renderer #{name} not found")
      if Array === renderer
        get_first(renderer)
      elsif String === renderer
        get(renderer)
      elsif renderer.init
        renderer
      end
    end

    def choose(name)
      get(name) || get_first(registry.keys) || raise('No renderer found')
    end
  end
end

class RitexRenderer < MathRenderer
  def load
    require 'ritex'
    true
  end

  def render(code, display)
    Ritex::Parser.new.parse(code)
  end
end

class ItexRenderer < MathRenderer
  def load
    `itex2MML --version`
  end

  def render(code, display)
    Shell.itex2MML(display == 'block' ? '--display' : '--inline').run(code.strip)
  end
end

class BlahtexMLRenderer < MathRenderer
  def load
    `blahtex`
  end

  def render(code, display)
    content = Shell.blahtex('--mathml').run(code.strip)
    content =~ %r{<mathml>(.*)</mathml>}m
    '<mathml xmlns="http://www.w3.org/1998/Math/MathML" display="' + display + '">' + $1.to_s + '</mathml>'
  end
end

class BlahtexImageRenderer < MathRenderer
  include PageHelper

  def load
    `blahtex`
  end

  def self.directory
    @directory ||= File.join(Config.tmp_path, 'blahtex').tap {|dir| FileUtils.mkdir_p dir, :mode => 0755 }
  end

  def render(code, display)
    content = Shell.blahtex('--png', '--png-directory', BlahtexImageRenderer.directory).run(code.strip)
    if content =~ %r{<md5>(.*)</md5>}m
      path = absolute_path "_/tag/math/blahtex/#{$1}.png"
      %{<img src="#{escape_html path}" alt="#{escape_html code}" class="math #{display}"/>}
    elsif content.include?('error') && content =~ %r{<message>(.*)</message>}
      raise $1
    end
  end
end

class GoogleRenderer < MathRenderer
  def render(code, display)
    %{<img src="http://chart.apis.google.com/chart?cht=tx&amp;chl=#{escape code}" alt="#{escape_html code}" class="math #{display}"/>}
  end
end

class LaTeXRenderer < MathRenderer
  def render(code, display)
    display == 'inline' ? "\\(#{escape_html(code)}\\)" : "\\[#{escape_html(code)}\\]"
  end
end

MathRenderer.registry = {
  'mathml/itex'    => ItexRenderer.new,
  'mathml/ritex'   => RitexRenderer.new,
  'mathml/blahtex' => BlahtexMLRenderer.new,
  'mathml/mathjax' => LaTeXRenderer.new,
  'image/blahtex'  => BlahtexImageRenderer.new,
  'image/google'   => GoogleRenderer.new,
}

Tag.define :math do |context, attrs, code|
  raise('Limits exceeded') if code.size > 10240
  mode = context.page.attributes['math'] || Config.math_renderer
  MathRenderer.choose(mode).render(code, attrs['display'] == 'block' ? 'block' : 'inline')
end

class Olelo::Application
  attribute_editor do
    attribute :math, MathRenderer.registry.keys
  end

  hook :layout_xml do |name, xml|
    if xml =~ /\\\[|\\\(|\\begin\{/
      xml.sub!('</body>', %{<script src="#{absolute_path 'static/mathjax/MathJax.js'}" type="text/javascript" async="async"/></body>})
    end
  end

  get '/_/tag/math/blahtex/:name', :name => /[\w\.]+/ do
    begin
      response['Content-Type'] = 'image/png'
      file = File.join(BlahtexImageRenderer.directory, params[:name])
      response['Content-Length'] ||= File.stat(file).size.to_s
      halt BlockFile.open(file, 'rb')
    rescue => ex
      ImageMagick.label(ex.message)
    end
  end
end
