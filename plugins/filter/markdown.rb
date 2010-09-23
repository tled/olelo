description  'Markdown text filter'
dependencies 'engine/filter'
require      'rdiscount'

Filter.create :markdown do |context, content|
  RDiscount.new(content, :filter_html).to_html
end
