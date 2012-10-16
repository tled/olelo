description 'Wraps fragment into html block to make it valid'

Filter.create :html_wrapper do |context, content|
  %{<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>#{escape_html context.page.title}</title>
  </head>
  <body><div>#{content}</div></body>
</html>}
end
