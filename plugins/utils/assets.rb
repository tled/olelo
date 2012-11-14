description 'Asset manager'

class ::Olelo::Application
  @assets = {}
  @scripts = {}

  class << self
    attr_reader :assets, :scripts
  end

  attr_reader? :disable_assets

  hook :head, 2 do
    return if disable_assets?
    js = Application.scripts['js']
    css = Application.scripts['css']
    result = ''
    if css
      path = build_path "_/assets/assets.css?#{css.first}"
      result << %{<link rel="stylesheet" href="#{escape_html path}" type="text/css"/>}
    end
    if js
      path = build_path "_/assets/assets.js?#{js.first}"
      result << %{<script src="#{escape_html path}" type="text/javascript"></script>}
    end
    result
  end

  get "/_/assets/assets.:type", type: 'js|css' do
    if script = Application.scripts[params[:type]]
      cache_control max_age: :static, must_revalidate: false, etag: script.first
      response['Content-Type'] = MimeMagic.by_extension(params[:type]).to_s
      response['Content-Length'] = script.last.bytesize.to_s
    else
      :not_found
    end
  end

  get "/_/assets/:name", name: '.*' do
    if asset = Application.assets[params[:name]]
      fs, name = asset
      if path = fs.real_path(name)
        file = Rack::File.new(nil)
        file.path = path
        file.serving(env)
      else
        cache_control last_modified: fs.mtime(name), max_age: :static
        response['Content-Type'] = (MimeMagic.by_path(name) || 'application/octet-stream').to_s
        response['Content-Length'] = fs.size(name).to_s
        fs.read(name)
      end
    else
      :not_found
    end
  end
end

class ::Olelo::Plugin
  def export_assets(*files)
    virtual_fs.glob(*files) do |fs, name|
      Application.assets[path/name] = [fs, name]
    end
  end

  def export_scripts(*files)
    virtual_fs.glob(*files) do |fs, name|
      raise 'Invalid script type' if name !~ /\.(css|js)$/
      scripts = Application.scripts[$1].to_a
      code = "#{scripts[1]}/* #{path/name} */\n#{fs.read(name)}\n"
      Application.scripts[$1] = [md5(code), code]
    end
  end
end
