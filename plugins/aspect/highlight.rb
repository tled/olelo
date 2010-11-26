description  'Source code highlighting aspect'
dependencies 'aspect/aspect', 'utils/pygments'

Aspect.create(:highlight, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(page); !page.content.empty? && Pygments.file_format(page.name); end
  def output(context); Pygments.pygmentize(context.page.content, Pygments.file_format(context.page.name)); end
end

