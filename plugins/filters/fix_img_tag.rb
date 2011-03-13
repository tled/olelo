description 'Add query parameter "aspect" to images'

Filter.create :fix_img_tag do |context, content|
 content.gsub!(/(<img[^>+]src=")([^"]+)"/) do |match|
    prefix, path = $1, $2
    if path =~ %r{^w+://} || path.starts_with?(build_path('_')) ||
        (path.starts_with?('/') && !path.starts_with?(build_path(''))) ||
        path.include?('aspect=')
      match
    else
      path = unescape_html(path)
      prefix + escape_html(path + (path.include?('?') ? '&' : '?') + 'aspect=image') + '"'
    end
  end
  content
end
