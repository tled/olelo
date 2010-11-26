description  'Text aspect'
dependencies 'aspect/aspect'

Aspect.create(:text, :mime => 'text/plain; charset=utf-8') do
  def accepts?(page); page.mime.text?; end
  def output(context)
    context.header['Content-Length'] = context.page.content.bytesize.to_s
    context.page.content
  end
end
