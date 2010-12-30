description 'Download aspect'

Aspect.create(:download) do
  def accepts?(page); !page.content.empty?; end
  def call(context, page)
    name = page.root? ? :root.t : page.name.gsub(/[^\w.\-_]/, '_')
    context.header['Content-Disposition'] = %{attachment; filename="#{name}"}
    context.header['Content-Length'] = page.content.bytesize.to_s
    page.content
  end
end
