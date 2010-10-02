description  'Tabs'
dependencies 'filter/tag'

Tag.define :tabs do |context, attrs, content|
  tabs = context.private[:tabs] = []
  prefix = (context.private[:tabs_prefix] ||= 0)
  content = subfilter(context, content)
  li = []
  tabs.each_with_index do |name, i|
    li << %{<li id="tabhead-#{prefix}-#{i}"><a href="#tab-#{prefix}-#{i}">#{escape_html name}</a></li>}
  end
  context.private.delete(:tabs)
  context.private[:tabs_prefix] += 1
  %{<ul class="tabs">#{li.join}</ul>} + content
end

Tag.define :tab, :requires => :name do |context, attrs, content|
  raise '<tab> can only be used in <tabs>' if !context.private[:tabs]
  context.private[:tabs] << attrs['name']
  %{<div class="tab" id="tab-#{context.private[:tabs_prefix]}-#{context.private[:tabs].size - 1}">#{subfilter(context, content)}</div>}
end
