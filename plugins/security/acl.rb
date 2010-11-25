description 'Access control lists'

class Olelo::AccessDenied < RuntimeError
  def initialize
    super(:access_denied.t)
  end

  def status
    :forbidden
  end
end

class Olelo::Page
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
    parent.access?(:delete)
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

class Olelo::Application
  hook :dom, 999 do |name, doc, layout|
    if page && layout
      doc.css('#menu .action-edit').each {|link| link.delete('href') } if !page.writable?
      if !page.root?
        doc.css('#menu .action-delete').each {|link| link.parent.remove } if !page.deletable?
        doc.css('#menu .action-move').each {|link| link.parent.remove } if !page.movable?
      end
    end
  end
end

