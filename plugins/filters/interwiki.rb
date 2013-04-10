description 'Handle interwiki links'

class Interwiki < Filter
  def configure(options)
    super
    @map = options[:map]
    @map[Config['interwiki']] = Config['base_path']
    @regexp = /href="\/?(#{@map.keys.join('|')}):([^"]+)"/
  end

  def filter(context, content)
    content.gsub!(@regexp) do
      %{href="#{escape_html @map[$1]}#{$2}"}
    end
    content
  end
end

Filter.register :interwiki, Interwiki
