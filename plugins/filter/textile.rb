description  'Textile text filter'
dependencies 'aspect/filter'
require      'redcloth'

Filter.create :textile do |context, content|
  doc = RedCloth.new(content)
  doc.sanitize_html = true
  doc.to_html
end
