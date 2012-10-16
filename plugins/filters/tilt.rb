description 'Tilt filter'
require 'tilt'

class TiltFilter < Filter
  def filter(context, content)
    Tilt[name].new { content }.render
  end
end

Filter.register :markdown, TiltFilter
Filter.register :textile, TiltFilter
Filter.register :sass, TiltFilter
Filter.register :scss, TiltFilter
Filter.register :less, TiltFilter
Filter.register :rdoc, TiltFilter
Filter.register :coffee, TiltFilter
Filter.register :mediawiki, TiltFilter
