description  'Export variables to context and javascript'
dependencies 'aspects'

def self.exported_variables(page)
  vars = {
    'base_path'             => Config['base_path'],
    'page_name'             => page.name,
    'page_new'              => page.new?,
    'page_modified'         => page.modified?,
    'page_path'             => page.path,
    'page_title'            => page.title,
    'page_version'          => page.version.to_s,
    'page_next_version'     => page.next_version.to_s,
    'page_previous_version' => page.previous_version.to_s,
    'page_mime'             => page.mime.to_s,
    'default_mime'          => Page.default_mime
  }
end

# Export variables to aspect context
Aspects::Context.hook(:initialized) do
  params.merge!(PLUGIN.exported_variables(page))
end

# Export variables to javascript for client extensions
Application.hook :head do
  vars = page ? params.merge(PLUGIN.exported_variables(page)) : params
  vars = vars.merge('user_logged_in' => !User.logged_in?, 'user_name' => User.current.name)
  %{<script type="text/javascript">Olelo = #{escape_javascript(vars.to_json)};</script>}
end
