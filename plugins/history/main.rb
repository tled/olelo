description 'History menu'
dependencies 'utils/assets'
export_scripts '*.js'

class ::Olelo::Application
  get '/compare/:versions(/(:path))', versions: '(?:\w+)\.{2,3}(?:\w+)' do
    @page = Page.find!(params[:path])
    versions = params[:versions].split(/\.{2,3}/)
    begin
      @diff = page.diff(versions.first, versions.last)
    rescue => ex
      Olelo.logger.debug ex
      raise NotFound
    end
    render :compare
  end

  get '/compare(/(:path))' do
    versions = params[:versions] || []
    redirect build_path(params[:path], action: versions.size < 2 ? :history : "compare/#{versions.first}...#{versions.last}")
  end

  get '/changes/:version(/(:path))' do
    @page = Page.find!(params[:path])
    begin
      @diff = page.diff(nil, params[:version])
    rescue => ex
      Olelo.logger.debug ex
      raise NotFound
    end
    @version = @diff.to
    cache_control etag: @version.to_s
    render :changes
  end

  get '/history(/(:path))' do
    per_page = 30
    @page = Page.find!(params[:path])
    @page_nr = [params[:page].to_i, 1].max
    @history = page.history((@page_nr - 1) * per_page, per_page + 1)
    @page_count = @page_nr + (@history.length > per_page ? 1 : 0)
    @history = @history[0...per_page]
    cache_control etag: page.etag
    render :history
  end

  before :action do |method, path|
    @history_versions_menu = method == :get && (path == '/version/:version(/(:path))' || path == '/(:path)')
  end

  hook :menu do |menu|
    if menu.name == :actions && page && !page.new?
      history_menu = menu.item(:history, href: build_path(page, action: :history), accesskey: 'h')

      if @history_versions_menu
        history_menu.append(Cache.cache("history-menu-#{page.path}-#{page.etag}", update: no_cache?, defer: true) do
          head = !page.head? && (Olelo::Page.find(page.path) rescue nil)
          items = []
          if page.previous_version || head || page.next_version
            items << MenuItem.new(:older, href: build_path(page, original_params.merge(version: page.previous_version)),
                                  accesskey: 'o') if page.previous_version
            items << MenuItem.new(:head, href: build_path(page.path, original_params), accesskey: 'c') if head
            items << MenuItem.new(:newer, href: build_path(page, original_params.merge(version: page.next_version)),
                                  accesskey: 'n') if page.next_version
          end
          items
        end)
      end
    end
  end
end
