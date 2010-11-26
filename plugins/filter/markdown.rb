description  'Markdown text filter'
dependencies 'aspect/filter'
require      'rdiscount'

Filter.create :markdown do |context, content|
  RDiscount.new(content, :filter_html).to_html
end
