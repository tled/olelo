description 'Include tags'

Tag.define :include, :optional => '*', :requires => :page, :limit => 10, :description => 'Include page' do |context, attrs|
  path = attrs['page']
  path = context.page.path/'..'/path if !path.starts_with? '/'
  if page = Page.find(path, context.page.tree_version)
    Aspects::Aspect.find!(page, :name => attrs['aspect'], :layout => true).
      call(context.subcontext(:params => attrs.merge(:included => true), :page => page), page)
  else
    %{<a href="#{escape_html build_path('new'/path)}">#{escape_html :create_page.t(:page => path)}</a>}
  end
end

Tag.define :includeonly, :immediate => true, :description => 'Text which is shown only if included' do |context, attrs, content|
  nested_tags(context.subcontext, content) if context.params[:included]
end

Tag.define :noinclude, :immediate => true, :description => 'Text which is not included' do |context, attrs, content|
  nested_tags(context.subcontext, content) if !context.params[:included]
end
