description 'Text aspect'

Aspect.create(:text, :mime => 'text/plain; charset=utf-8') do
  def accepts?(page); page.mime.text?; end
  def call(context, page)
    context.header['Content-Length'] = page.content.bytesize.to_s
    page.content
  end
end
