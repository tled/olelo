description 'Access control lists'

class ::Olelo::Page
  attributes do
    group :acl do
      list :write
      list :create
      list :delete
    end
  end

  # New page is writable if parent allows page creation
  # Existing page is writable if page is writable
  def writable?
    new? ? (root? || parent.access?(:create)) : access?(:write)
  end

  # Page is deletable if parent is writable
  def deletable?
    parent && parent.access?(:delete)
  end

  # Page is movable if page is deletable and destination is writable
  def movable?(destination = nil)
    deletable? && (!destination || (Page.find(destination) || Page.new(destination)).writable?)
  end

  def access?(type)
    acl = saved_attributes['acl'] || {}
    names = [*acl[type.to_s]].compact
    names.empty? ||
    names.include?(User.current.name) ||
    User.current.groups.any? {|group| names.include?('@'+group) }
  end

  before :save, 999 do
    raise(AccessDenied) if !writable?
  end

  before :delete, 999 do
    raise(AccessDenied) if !deletable?
  end

  before :move, 999 do |destination|
    raise(AccessDenied) if !movable?(destination)
  end
end

class ::Olelo::Application
  hook :menu, 999 do |menu|
    if menu.name == :actions && page
      menu.remove('edit/delete') if !page.deletable?
      menu.remove('edit/move') if !page.movable?
      menu['edit'].options.delete(:href) if menu['edit'] && !page.writable?
    end
  end
end

__END__
@@ locale.yml
cs_CZ:
  attribute_acl_create: 'Vytvářet podstránky'
  attribute_acl_delete: 'Mazat podstránky'
  attribute_acl_write:  'Právo zápisu'
  group_acl:            'Řízení přístupů (ACL)'
de:
  attribute_acl_create: 'Unterseiten anlegen'
  attribute_acl_delete: 'Unterseiten löschen'
  attribute_acl_write:  'Schreibzugriff'
  group_acl:            'Zugriffslisten'
en:
  attribute_acl_create: 'Create subpages'
  attribute_acl_delete: 'Delete subpages'
  attribute_acl_write:  'Write access'
  group_acl:            'Access control lists'
fr:
  attribute_acl_create: "Créer sous-pages"
  attribute_acl_delete: "Supprimer sous-pages"
  attribute_acl_write:  "Accès en écriture"
  group_acl:            "Liste de contrôle des accès"
