description  'Tabs'
dependencies 'filter/tag'

Tag.define :tabs do |context, attrs, content|
  tabs = context[:tabs] = []
  prefix = (context[:tabs_prefix] ||= 0)
  content = subfilter(context, content)
  li = []
  tabs.each_with_index do |name, i|
    li << %{<li id="tabhead-#{prefix}-#{i}"><a href="#tab-#{prefix}-#{i}">#{escape_html name}</a></li>}
  end
  context.private.delete(:tabs)
  context[:tabs_prefix] += 1
  %{<ul class="tabs">#{li.join}</ul>} + content
end

Tag.define :tab, :requires => :name do |context, attrs, content|
  raise '<tab> can only be used in <tabs>' if !context[:tabs]
  context[:tabs] << attrs['name']
  %{<div class="tab" id="tab-#{context[:tabs_prefix]}-#{context[:tabs].size - 1}">#{subfilter(context, content)}</div>}
end
