description  'Export variables to context and javascript'
dependencies 'aspects'

def self.exported_global_variables
  {
    'base_path'             => Config['base_path'],
    'default_mime'          => Page.default_mime
  }
end

def self.exported_page_variables(page)
  {
    'page_name'             => page.name,
    'page_new'              => page.new?,
    'page_modified'         => page.modified?,
    'page_path'             => page.path,
    'page_title'            => page.title,
    'page_version'          => page.version.to_s,
    'page_next_version'     => page.next_version.to_s,
    'page_previous_version' => page.previous_version.to_s,
    'page_mime'             => page.mime.to_s
  }
end

# Export variables to aspect context
Aspects::Context.hook(:initialized) do
  params.merge!(PLUGIN.exported_global_variables)
  params.merge!(PLUGIN.exported_page_variables(page))
end

# Export variables to javascript for client extensions
Application.hook :head, 1 do
  vars = params.merge(PLUGIN.exported_global_variables)
  if page
    vars.merge!(Cache.cache("variables-#{page.path}-#{page.etag}", update: no_cache?, defer: true) do |cache|
      PLUGIN.exported_page_variables(page)
    end)
  end
  vars = vars.merge('user_name' => User.current.name) if User.logged_in?
  %{<script type="text/javascript">Olelo = #{escape_javascript MultiJson.dump(vars)};</script>}
end
