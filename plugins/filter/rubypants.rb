description  'Filter which fixes punctuation'
dependencies 'aspect/filter'
require      'rubypants'

Filter.create :rubypants do |context, content|
  RubyPants.new(content).to_html
end
