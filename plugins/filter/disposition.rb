description  'Filter which sets Content-Disposition'
dependencies 'aspect/filter'

Filter.create :disposition do |context, content|
  name = context.page.root? ? :root.t : context.page.name.gsub(/[^\w.\-_]/, '_')
  name += '.' + options[:extension] if options[:extension]
  context.header['Content-Disposition'] = %{attachment; filename="#{name}"}
  context.header['Content-Length'] = content.bytesize.to_s
  content
end
