description    'Tag to redirect to other pages'

Application.hook :render do |name, xml, layout|
  if params[:redirect] && layout
    links = [params[:redirect]].flatten.map do |link|
      %{<a href="#{escape_html build_path(link, :action => :edit)}">#{escape_html link}</a>}
    end.join(' &#8594; ')
    xml.sub!(/<div id="menu">.*?<\/ul>/m, "\\0Redirected from #{links} &#8594; &#9678; ")
  end
end

Tag.define :redirect, :requires => 'to', :dynamic => true do |context, attrs|
  list = context.params[:redirect] || []
  to = attrs['to']
  if list.include?(to)
    raise "Invalid redirect to #{to}"
  else
    list << context.page.path
    throw :redirect, build_path(to, 'redirect[]' => list, :version => !context.page.head? && context.page)
  end
end
