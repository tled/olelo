description 'Forbid anonymous access, redirect to login'

class ::Olelo::Application
  PUBLIC_ACCESS = %w(/login)

  redefine_method :include_page do |path|
    User.logged_in? ? super(path) : ''
  end

  hook :menu, 999 do |menu|
    menu.clear if menu.name == :actions && !User.logged_in?
  end

  before :routing do
    if !User.logged_in?
      if !PUBLIC_ACCESS.include?(request.path_info)
        flash.error :login_first.t
        session[:olelo_goto] = request.path_info if request.get? && request.path_info !~ %r{^/_/}
        redirect build_path(:login)
      end
      @disable_assets = true
    end
  end
end

__END__
@@ locale.yml
cs_CZ:
  login_first:          'Musíte se nejprve přihlásit'
de:
  login_first:          'Sie müssen sich zuerst anmelden'
en:
  login_first:          'You have to login first'
fr:
  login_first:          "Vous devez d'abord vous connecter"
