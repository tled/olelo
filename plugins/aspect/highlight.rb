description  'Source code highlighting aspect'
dependencies 'aspect/aspect', 'utils/pygments'

Aspect.create(:highlight, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(page); !page.content.empty? && Pygments.file_format(page.name); end
  def call(context, page); Pygments.pygmentize(page.content, Pygments.file_format(page.name)); end
end

