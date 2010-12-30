description  'Persistent login'
dependencies 'utils/store'
require 'securerandom'

class ::Olelo::Application
  TOKEN_NAME = 'olelo.token'
  TOKEN_LIFETIME = 24*60*60*365

  def login_tokens
    @login_tokens ||= Store.create(Config['tokens_store'])
  end

  hook :auto_login do
    if !User.current
      token = request.cookies[TOKEN_NAME]
      if token
        user = login_tokens[token]
        User.current = User.find(user) if user
      end
    end
  end

  before :login_buttons do
    %{<input type="checkbox" name="persistent" id="persistent" value="1"/>
      <label for="persistent">#{escape_html :persistent_login.t}</label><br/>}.unindent
  end

  after :action do |method, path|
    if path == '/login'
      if User.logged_in? && params[:persistent]
        token = SecureRandom.hex
        response.set_cookie(TOKEN_NAME, :value => token, :expires => Time.now + TOKEN_LIFETIME)
        login_tokens[token] = User.current.name
      end
    elsif path == '/logout'
      token = request.cookies[TOKEN_NAME]
      login_tokens.delete(token)
      response.delete_cookie(TOKEN_NAME)
    end
  end
end
