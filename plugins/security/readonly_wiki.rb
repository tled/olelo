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
  hook :render, 999 do |name, xml, layout|
    xml.gsub!(/<a[^>]+class="[^"]*editsection.*?<\/a>/, '') if !User.logged_in?
  end

  hook :menu, 999 do |menu|
    menu.remove(:edit) if menu.name == :actions && !User.logged_in?
  end
end
