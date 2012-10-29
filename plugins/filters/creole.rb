description  'Creole wiki text filter'
require 'creole'

class OleloCreole < ::Creole::Parser
  include PageHelper
  include Util

  def make_image(path, title)
    args = title.to_s.split('|')
    image_path = path.dup
    if path !~ %r{^(\w+)://}
      geometry = args.grep(/(\d+x)|(x\d+)|(\d+%)/).first
      image_path += (path.include?('?') ? '&' : '?') + 'aspect=image'
      if geometry
        args.delete(geometry)
        image_path += "&geometry=#{geometry}"
      end
    end
    image_path = escape_html(image_path)
    path = escape_html(path)
    box = args.delete('box')
    alt = escape_html(args[0] ? args[0] : path)
    if box
      caption = args[0] ? %{<span class="caption">#{escape_html args[0]}</span>} : ''
      %{<span class="img"><img src="#{image_path}" alt="#{alt}"/>#{caption}</span>}
    else
      %{<img src="#{image_path}" alt="#{alt}"/>}
    end
  end
end

Filter.create :creole do |context, content|
  OleloCreole.new(content, extensions: true, no_escape: true).to_html
end
