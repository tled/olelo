description 'Forbid anonymous access, redirect to login'

class Olelo::Application
  PUBLIC_ACCESS = %w(/login)

  hook :layout, 999 do |name, doc|
    doc.css('#menu .actions, #info, #search, #sidebar *, script[src*=assets], link[href*=assets], form[action*=signup], #tabhead-signup').remove if !User.logged_in?
  end

  before :routing do
    if !User.logged_in? && !PUBLIC_ACCESS.include?(request.path_info)
      session[:olelo_goto] = request.path_info if request.path_info !~ %r{^/_/}
      redirect '/login'
    end
  end
end
