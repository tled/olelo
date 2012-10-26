description 'Filter which converts html to xml'
dependencies 'utils/xml'

Filter.create :html2xml do |context, content|
  XML::Fragment(content).to_xhtml
end
