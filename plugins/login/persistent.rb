# -*- coding: utf-8 -*-
description  'Persistent login'
require 'openssl'

class ::Olelo::Application
  TOKEN_NAME = 'olelo.token'
  TOKEN_LIFETIME = 24*60*60*365

  hook :auto_login do
    if !User.current
      token = request.cookies[TOKEN_NAME]
      if token
        hash, user = token.split('-', 2)
        User.current = User.find(user) if hash == OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'),
                                                                       Config['rack.session_secret'], user)
      end
    end
  end

  after :action do |method, path|
    if path == '/login'
      if User.logged_in? && params[:persistent]
        hash = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'),
                                    Config['rack.session_secret'], User.current.name)
        response.set_cookie(TOKEN_NAME, value: "#{hash}-#{User.current.name}", expires: Time.now + TOKEN_LIFETIME)
      end
    elsif path == '/logout'
      response.delete_cookie(TOKEN_NAME)
    end
  end

  before(:login_buttons) { render_partial :persistent_login }
end

__END__
@@ persistent_login.slim
&checkbox#persistent name="persistent" value="1"
label for="persistent" = :persistent_login.t
br
@@ locale.yml
cs:
  persistent_login:     'Trvalé přihlášení'
de:
  persistent_login:     'Dauerhaft anmelden'
en:
  persistent_login:     'Persistent login'
fr:
  persistent_login:     'Connexion persistente'
