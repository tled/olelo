description 'Tilt filter'
require 'tilt'

class TiltFilter < Filter
  def filter(context, content)
    Tilt[name].new { content }.render
  end
end

Filter.register :markdown, TiltFilter
Filter.register :textile, TiltFilter
