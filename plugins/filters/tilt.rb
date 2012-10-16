description 'Tilt filter'
require 'tilt'

class TiltFilter < Filter
  def filter(context, content)
    ::Tilt[name].new { content }.render
  end
end

[:markdown, :textile, :sass, :scss, :less, :rdoc, :coffee, :mediawiki].each do |name|
  begin
    ::Tilt[name].new { '' } # Force initialization of tilt library
    Filter.register(name, TiltFilter)
  rescue Exception => ex
    Olelo.logger.warn "Could not load Tilt filter #{name}"
  end
end
