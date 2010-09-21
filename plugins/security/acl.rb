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
  # New page is writable if parent is writable
  # Existing page is writable if page is writable
  def writable?
    new? ? (root? || parent.writable?) : access?(:write)
  end

  # Page is deletable if parent is writable
  def deletable?
    parent.writable?
  end

  # Page is movable if parent is writable and destination is writable
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

  before(:save, 999) do
    raise(AccessDenied) if !writable?
  end

  before(:delete, 999) do
    raise(AccessDenied) if !deletable?
  end

  before(:move, 999) do |destination|
    raise(AccessDenied) if !movable?(destination)
  end

  metaclass.redefine_method :find do |*args|
    path, tree_version, current = *args
    page = super(path, tree_version)
    raise(AccessDenied) if page && !page.access?(:read)
    find(path/'..', tree_version, current) if !path.blank?
    page
  end
end

class Olelo::Application
  attribute_editor do
    group :acl do
      attribute :read, :stringlist
      attribute :write, :stringlist
    end
  end

  hook :layout, 999 do |name, doc|
    if page
      doc.css('#menu .action-edit').each {|link| link.delete('href') } if !page.writable?
      if !page.root?
        doc.css('#menu .action-delete').each {|link| link.parent.remove } if !page.deletable?
        doc.css('#menu .action-move').each {|link| link.parent.remove } if !page.movable?
      end
    end
  end

  hook AccessDenied do |ex|
    if !on_error
      if request.xhr?
        response['Content-Type'] = 'application/json; charset=utf-8'
        halt '"Access denied"'
      else
        cache_control :no_cache => true
        @page = nil
        session[:olelo_goto] = request.path_info if request.path_info !~ %r{^/_/}
        halt render(:access_denied)
      end
    end
  end
end

__END__
@@ access_denied.haml
- title :access_denied.t
.access_denied_page
  %h1= :access_denied.t
  = :access_denied_long.t
