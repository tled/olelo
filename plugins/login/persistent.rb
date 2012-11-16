description  'Persistent login'

class ::Olelo::Application
  TOKEN_NAME = 'olelo.token'
  TOKEN_LIFETIME = 24*60*60*365

  hook :auto_login do
    if !User.current
      token = request.cookies[TOKEN_NAME]
      if token
        hash, user = token.split('-', 2)
        User.current = User.find(user) if sha256(user + Config['rack.session_secret']) == hash
      end
    end
  end

  before :login_buttons do
    %{<input type="checkbox" name="persistent" id="persistent" value="1"/>
<label for="persistent">#{escape_html :persistent_login.t}</label><br/>}
  end

  after :action do |method, path|
    if path == '/login'
      if User.logged_in? && params[:persistent]
        token = "#{sha256(User.current.name + Config['rack.session_secret'])}-#{User.current.name}"
        response.set_cookie(TOKEN_NAME, value: token, expires: Time.now + TOKEN_LIFETIME)
      end
    elsif path == '/logout'
      response.delete_cookie(TOKEN_NAME)
    end
  end
end

__END__
@@ locale.yml
cs:
  persistent_login:     'Trvalé přihlášení'
de:
  persistent_login:     'Dauerhaft anmelden'
en:
  persistent_login:     'Persistent login'
fr:
  persistent_login:     'Connexion persistente'
