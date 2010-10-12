description  'Safe html tags'
dependencies 'filter/tag'

HTML_TAGS = [
  [:a, {:optional => %w(href title)}],
  [:img, {:autoclose => true, :optional => %w(src alt title)}],
  [:br, {:autoclose => true}],
  [:i],
  [:u],
  [:b],
  [:pre],
  [:kbd],
  # provided by syntax highlighter
  # [:code, :optional => %w(lang)]
  [:cite],
  [:strong],
  [:em],
  [:ins],
  [:sup],
  [:sub],
  [:del],
  [:table],
  [:tr],
  [:td, {:optional => %w(colspan rowspan)}],
  [:th],
  [:ol, {:optional => %w(start)}],
  [:ul],
  [:li],
  [:p],
  [:h1],
  [:h2],
  [:h3],
  [:h4],
  [:h5],
  [:h6],
  [:blockquote, {:optional => %w(cite)}],
  [:div, {:optional => %w(style)}],
  [:span, {:optional => %w(style)}],
  [:video, {:optional => %w(autoplay controls height width loop preload src poster)}],
  [:audio, {:optional => %w(autoplay controls loop preload src)}]
]

# Extra function because of ruby 1.8 block scoping
def define_html_tag(name, options)
  if options.delete(:autoclose)
    Tag.define name, options do |context, attrs|
      attrs = attrs.map {|(k,v)| %{#{k}="#{escape_html v}"} }.join
      "<#{name}#{attrs.blank? ? '' : ' '+attrs}/>"
    end
  else
    Tag.define name, options do |context, attrs, content|
      attrs = attrs.map {|(k,v)| %{#{k}="#{escape_html v}"} }.join
      content = subfilter(context.subcontext, content)
      content.gsub!(/(\A<p[^>]*>)|(<\/p>\Z)/, '')
      "<#{name}#{attrs.blank? ? '' : ' '+attrs}>#{content}</#{name}>"
    end
  end
end

HTML_TAGS.each {|name, options| define_html_tag(name, options || {}) }
