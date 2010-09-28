description  'Math tag for LaTeX rendering'
dependencies 'filter/tag'

class Olelo::MathRenderer
  include Util
  extend Factory

  def self.setup
    registry.each do |name, klass|
      begin
        registry[name] = klass.new
      rescue Exception => ex
        registry.delete(name)
        Plugin.current.logger.warn "Failed to initialize math renderer #{name}: #{ex.message}"
      end
    end
  end
end

def setup
  MathRenderer.setup
end

class RitexRenderer < MathRenderer
  def initialize
    require 'ritex'
  end

  def render(code, display)
    Ritex::Parser.new.parse(code)
  end

  def description

  end

  register 'ritex', RitexRenderer
end

class ItexRenderer < MathRenderer
  def initialize
    `itex2MML --version`
    raise 'itex2MML not found on path' if $?.exitstatus != 0
  end

  def render(code, display)
    Shell.itex2MML(display == 'block' ? '--display' : '--inline').run(code.strip)
  end

  register 'itex', ItexRenderer
end

class BlahtexMLRenderer < MathRenderer
  def initialize
    `blahtex`
    raise 'blahtex not found on path' if $?.exitstatus != 0
  end

  def render(code, display)
    content = Shell.blahtex('--mathml').run(code.strip)
    content =~ %r{<mathml>(.*)</mathml>}m
    '<mathml xmlns="http://www.w3.org/1998/Math/MathML" display="' + display + '">' + $1.to_s + '</mathml>'
  end

  register 'blahtexml', BlahtexMLRenderer
end

class BlahtexImageRenderer < MathRenderer
  include PageHelper

  def initialize
    `blahtex`
    raise 'blahtex not found on path' if $?.exitstatus != 0
    FileUtils.mkpath(Config.blahtex_directory)
  end

  def render(code, display)
    content = Shell.blahtex('--png', '--png-directory', Config.blahtex_directory).run(code.strip)
    if content =~ %r{<md5>(.*)</md5>}m
      path = absolute_path "_/tag/math/blahtex/#{$1}.png"
      %{<img src="#{escape_html path}" alt="#{escape_html code}" class="math #{display}"/>}
    elsif content.include?('error') && content =~ %r{<message>(.*)</message>}
      raise $1
    end
  end

  register 'blahteximage', BlahtexImageRenderer
end

class GoogleRenderer < MathRenderer
  def render(code, display)
    %{<img src="http://chart.apis.google.com/chart?cht=tx&amp;chl=#{escape code}" alt="#{escape_html code}" class="math #{display}"/>}
  end

  register 'google', GoogleRenderer
end

class LaTeXRenderer < MathRenderer
  def render(code, display)
    display == 'inline' ? "\\(#{escape_html(code)}\\)" : "\\[#{escape_html(code)}\\]"
  end

  register 'latex',   LaTeXRenderer
  register 'mathjax', LaTeXRenderer
end

Tag.define :math do |context, attrs, code|
  raise('Limits exceeded') if code.size > 10240
  renderer = context.page.attributes['math'] || Config.math_renderer
  (MathRenderer[renderer] || MathRenderer['latex']).render(code, attrs['display'] == 'block' ? 'block' : 'inline')
end

class Olelo::Application
  attribute_editor do
    attribute :math do
      Hash[*MathRenderer.registry.keys.map {|m| [m, Locale.translate("math_#{m}")] }.flatten]
    end
  end

  hook :layout_xml do |name, xml|
    if xml =~ /\\\[|\\\(|\\begin\{/ && page && (page.attributes['math'] || Config.math_renderer) == 'mathjax'
      xml.sub!('</body>', %{<script src="#{absolute_path 'static/mathjax/MathJax.js'}" type="text/javascript" async="async"/></body>})
    end
  end

  get '/_/tag/math/blahtex/:name', :name => /[\w\.]+/ do
    begin
      response['Content-Type'] = 'image/png'
      file = File.join(Config.blahtex_directory, params[:name])
      response['Content-Length'] ||= File.stat(file).size.to_s
      halt BlockFile.open(file, 'rb')
    rescue => ex
      ImageMagick.label(ex.message)
    end
  end
end
