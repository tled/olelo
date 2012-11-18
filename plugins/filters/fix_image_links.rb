description 'Add query parameter "aspect" to images'
dependencies 'utils/xml'

Filter.create :fix_image_links do |context, content|
  doc = XML::Fragment(content)
  linked_images = doc.css('a img')
  doc.css('img').each do |image|
    path = image['src'] || next
    unless path =~ %r{^w+://} || path.starts_with?(build_path('_')) ||
        (path.starts_with?('/') && !path.starts_with?(build_path('')))
      unless path.include?('aspect=')
        image['src'] = path + (path.include?('?') ? '&' : '?') + 'aspect=image'
      end
      unless linked_images.include?(image)
        image.swap("<a href=\"#{escape_html path.sub(/\?.*/, '')}\">#{image.to_xhtml}</a>")
      end
    end
  end
  doc.to_xhtml
end
