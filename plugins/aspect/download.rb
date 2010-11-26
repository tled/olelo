description 'Download aspect'
dependencies 'aspect/aspect'

Aspect.create(:download) do
  def accepts?(page); !page.content.empty?; end
  def output(context)
    name = context.page.root? ? :root.t : context.page.name.gsub(/[^\w.\-_]/, '_')
    context.header['Content-Disposition'] = %{attachment; filename="#{name}"}
    context.header['Content-Length'] = context.page.content.bytesize.to_s
    context.page.content
  end
end
