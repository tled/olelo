description 'Read-only installation (editable only if logged in)'

class Olelo::Page
  before(:save, 999) do
    raise(AccessDenied) if !User.logged_in?
  end

  before(:delete, 999) do
    raise(AccessDenied) if !User.logged_in?
  end

  before(:move, 999) do |destination|
    raise(AccessDenied) if !User.logged_in?
  end
end

class Olelo::Application
  hook :dom, 999 do |name, doc, layout|
    doc.css('#menu .actions, #info, .editsection, form[action*=signup], #tabhead-signup').remove if !User.logged_in?
  end

  before :routing do
    redirect '/login' if !User.logged_in? && request.path_info == '/signup'
  end
end
