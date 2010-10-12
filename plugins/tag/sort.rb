description  'Tag which creates sorted list'
dependencies 'filter/tag'

Tag.define :sort, :optional => %w(ordered descending) do |context, attrs, content|
  type = attrs['ordered'] == 'ordered' ? 'ol' : 'ul'
  order = attrs['descending'] == 'descending' ? -1 : 1
  %{<#{type}>#{content.strip.split(/\n/).sort {|a,b| (a <=> b) * order }.map {|x| "<li>#{escape_html x}</li>"}.join}</#{type}>}
end
