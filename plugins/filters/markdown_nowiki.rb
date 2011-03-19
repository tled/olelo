description 'Markdown nowiki filter'

Filter.create :markdown_nowiki do |context, content|
  output = ''
  until content.blank?
    case content
    when /(\A( {4}|\t).*)|(\A``.*?``)|(\A`[^`]*`)/
      output << "<notags>#{$&}</notags>"
    when /(\A[^`\n]+)|(\A\n+)/
      output << $&
    end
    content = $'
  end
  output
end
