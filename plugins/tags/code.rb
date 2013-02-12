description  'Code tag with syntax highlighting'
dependencies 'utils/rouge'

Tag.define :code, optional: 'lang' do |context, attrs, content|
  ::Rouge.highlight(content, attrs['lang'] || ::Rouge::Lexer.guess_by_source(content), 'html')
end
