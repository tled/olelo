description 'Prints a fortune message (Dynamic example tag for development)'

Tag.define :fortune, :autoclose => true, :description => 'Show fortune message', :dynamic => true do |context, attrs|
  text = `fortune`
  "<blockquote>#{escape_html(text)}</blockquote>" if valid_xml_chars?(text)
end
