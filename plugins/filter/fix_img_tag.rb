description  'Add query parameter "output" to images'
dependencies 'engine/filter'

Filter.create :fix_img_tag do |context, content|
 content.gsub!(/(<img[^>+]src=")([^"]+)"/) do |match|
    prefix, path = $1, $2
    if path =~ %r{^w+://} || path.begins_with?(absolute_path('_')) ||
        (path.begins_with?('/') && !path.begins_with?(absolute_path(''))) ||
        path.include?('output=')
      match
    else
      path = unescape_html(path)
      prefix + escape_html(path + (path.include?('?') ? '&' : '?') + 'output=image') + '"'
    end
  end
  content
end
