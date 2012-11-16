# -*- coding: utf-8 -*-
description  'Source code highlighting aspect'
dependencies 'utils/pygments'

Aspect.create(:highlight, priority: 2, layout: true, cacheable: true) do
  def accepts?(page); !page.content.empty? && Pygments.file_format(page.name); end
  def call(context, page); Pygments.pygmentize(page.content, Pygments.file_format(page.name)); end
end

__END__
@@ locale.yml
cs:
  aspect_highlight: 'Zvýrazněný zdroj'
de:
  aspect_highlight: 'Quellcode mit Syntaxhighlighting'
en:
  aspect_highlight: 'Highlighted Source'
fr:
  aspect_highlight: "Source mise en valeur"
