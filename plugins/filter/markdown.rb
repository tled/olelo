description  'Markdown text filter'
dependencies 'engine/filter'
require      'rdiscount'

Filter.create :markdown do |context, content|
  content = RDiscount.new(content, :filter_html).to_html
  content.gsub!(/(<img[^>+]src=")([^"]+)"/) do |match|
    prefix, path = $1, $2
    if path.begins_with?('http://') || path.begins_with?('https://')
      match
    else
      path = unescape_html(path)
      prefix + escape_html(path + (path.include?('?') ? '&' : '?') + 'output=image') + '"'
    end
  end
  content
end
