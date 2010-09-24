description  'Include tags'
dependencies 'filter/tag'

Tag.define :include, :requires => :page, :limit => 10, :description => 'Include page' do |context, attrs, content|
  path = attrs['page']
  path = context.page.path/'..'/path if !path.starts_with? '/'
  if page = Page.find(path, context.page.tree_version, context.page.current?)
    Engine.find!(page, :name => attrs['output'], :layout => true).
      output(context.subcontext(:params => attrs.merge(:included => true), :page => page))
  else
    %{<a href="#{escape_html absolute_path('new'/path)}">#{escape_html :create_page.t(:page => path)}</a>}
  end
end

Tag.define :includeonly, :immediate => true, :description => 'Text which is shown only if included' do |context, attrs, content|
  nested_tags(context.subcontext, content) if context.params[:included]
end

Tag.define :noinclude, :immediate => true, :description => 'Text which is not included' do |context, attrs, content|
  nested_tags(context.subcontext, content) if !context.params[:included]
end
