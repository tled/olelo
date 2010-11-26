description 'Handle interwiki links'
dependencies 'aspect/filter'

class Interwiki < Filter
  def configure(options)
    super
    @map = options[:map]
    @regexp = /href="\/?(#{@map.keys.join('|')}):([^"]+)"/
  end

  def filter(context, content)
    content.gsub!(@regexp) do
      wiki, page = $1, $2
      %{href="#{escape_html @map[$1]}#{$2}"}
    end
    content
  end
end

Filter.register :interwiki, Interwiki
