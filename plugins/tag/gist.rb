description    'Tag to embed github gist'
dependencies   'filter/tag'
require        'open-uri'
export_scripts 'gist-embed.css'

Tag.define :gist, :requires => :id do |context, attrs|
  if attrs['id'] =~ /^\d+$/
    body = open("https://gist.github.com/#{attrs['id']}.json").read
    gist = JSON.parse(body)
    gist['div'].gsub('&nbsp;', '&#8239;')
  else
    raise ArgumentError, 'Invalid gist id'
  end
end
