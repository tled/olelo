description 'Simple webdav interface to the wiki files'

class Olelo::Application
  def webdav_post
    Page.transaction do
      page = request.put? ? Page.find!(params[:path]) : Page.new(params[:path])
      raise :reserved_path.t if self.class.reserved_path?(page.path)
      page.content = request.body
      page.save
      Page.commit(:page_uploaded.t(:page => page.title))
      :created
    end
  rescue NotFound => ex
    Olelo.logger.error ex
    :not_found
  rescue Exception => ex
    Olelo.logger.error ex
    :bad_request
  end

  put '/(:path)', :tail => true do
    if request.form_data?
      :not_implemented
    else
      webdav_post
    end
  end

  post '/(:path)', :tail => true do
    if request.form_data?
      super()
    else
      webdav_post
    end
  end

  # TODO: Implement more methods if needed
  add_route('PROPFIND', '/(:path)', :tail => true)  { :not_found }
  add_route('PROPPATCH', '/(:path)', :tail => true) { :not_implemented }
  add_route('MKCOL', '/(:path)', :tail => true)     { :not_implemented }
  add_route('COPY', '/(:path)', :tail => true)      { :not_implemented }
  add_route('MOVE', '/(:path)', :tail => true)      { :not_implemented }
  add_route('LOCK', '/(:path)', :tail => true)      { :not_implemented }
  add_route('UNLOCK', '/(:path)', :tail => true)    { :not_implemented }
end
