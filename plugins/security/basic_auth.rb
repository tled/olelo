description 'HTTP basic authentication'
require 'rack/auth/basic'

class ::Olelo::Application
  hook :auto_login do
    if params[:auth] && !User.current
      auth = Rack::Auth::Basic::Request.new(env)
      unauthorized if !auth.provided?
      halt :bad_request if !auth.basic?
      User.current = User.authenticate(auth.credentials[0], auth.credentials[1]) rescue nil
      unauthorized if !User.current
    end
  end

  private

  def unauthorized
    response['WWW-Authenticate'] = 'Basic realm="Olelo"'
    halt :unauthorized
  end
end
