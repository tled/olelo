description  'Source aspect'
dependencies 'aspect/aspect'

Aspect.create(:source, :priority => 3, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.text?; end
  def call(context, page); "<pre>#{escape_html page.content}</pre>"; end
end
