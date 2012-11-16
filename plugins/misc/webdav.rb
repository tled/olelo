description 'Simple webdav interface to the wiki files'

class ::Olelo::Application
  def webdav_post
    Page.transaction do
      page = request.put? ? Page.find!(params[:path]) : Page.new(params[:path])
      raise :reserved_path.t if self.class.reserved_path?(page.path)
      page.content = request.body
      page.save
      Page.commit(:page_uploaded.t(page: page.title))
      :created
    end
  rescue NotFound => ex
    Olelo.logger.error ex
    :not_found
  rescue Exception => ex
    Olelo.logger.error ex
    :bad_request
  end

  get '/webdav(/(:path))' do
    begin
      page = Page.find!(params[:path])
      cache_control etag: page.etag
      response['Content-Type'] = page.mime.to_s
      page.content
    rescue NotFound => ex
      Olelo.logger.error ex
      :not_found
    rescue Exception => ex
      Olelo.logger.error ex
      :bad_request
    end
  end

  put('/webdav(/(:path))') { webdav_post }
  post('/webdav(/(:path))') { webdav_post }

  # TODO: Implement more methods if needed
  add_route('PROPFIND', '/webdav(/(:path))')  { :not_found }
  add_route('PROPPATCH', '/webdav(/(:path))') { :not_implemented }
  add_route('MKCOL', '/webdav(/(:path))')     { :not_implemented }
  add_route('COPY', '/webdav(/(:path))')      { :not_implemented }
  add_route('MOVE', '/webdav(/(:path))')      { :not_implemented }
  add_route('LOCK', '/webdav(/(:path))')      { :not_implemented }
  add_route('UNLOCK', '/webdav(/(:path))')    { :not_implemented }
end
