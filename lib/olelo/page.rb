module Olelo
  class Version
    attr_reader :id, :author, :date, :comment, :parents

    def initialize(id, author, date, comment, parents)
      @id = id
      @author = author
      @date = date
      @comment = comment
      @parents = parents
    end

    def self.find(id)
      repository.find_version(id)
    end

    def self.find!(id)
      find(id) || raise(NotFound, id)
    end

    def short
      Version.short(id)
    end

    def self.short(id)
      repository.short_version(id)
    end

    def to_s
      id
    end

    def ==(other)
      other.to_s == id
    end

    def self.repository
      Repository.instance
    end
  end

  Diff = Struct.new(:from, :to, :patch)

  class Page
    include Util
    include Hooks

    PATH_PATTERN = '[^\s](?:.*[^\s]+)?'
    EMPTY_MIME = MimeMagic.new('application/x-empty')
    DIRECTORY_MIME = MimeMagic.new('inode/directory')

    attr_reader :path, :tree_version
    attr_reader? :current

    def initialize(path, tree_version = nil, current = true)
      @path = path.to_s.cleanpath.freeze
      @tree_version = tree_version
      @current = current
      Page.check_path(path)
    end

    def self.transaction(&block)
      repository.transaction(&block)
    end

    def self.commit(comment)
      repository.commit(comment)
    end

    # Throws exceptions if access denied, returns nil if not found
    def self.find(path, tree_version = nil, current = nil)
      path = path.to_s.cleanpath
      check_path(path)
      repository.find_page(path, tree_version, current.nil? ? tree_version.blank? : current)
    end

    # Throws if not found
    def self.find!(path, tree_version = nil, current = nil)
      find(path, tree_version, current) || raise(NotFound, path)
    end

    def root?
      path.empty?
    end

    def next_version
      init_versions
      @next_version
    end

    def previous_version
      init_versions
      @previous_version
    end

    def version
      init_versions
      @version
    end

    def history(skip = nil, limit = nil)
      raise 'Page is new' if new?
      repository.load_history(self, skip, limit)
    end

    def parent
      @parent ||= Page.find(path/'..', tree_version, current?) ||
        Page.new(path/'..', tree_version, current?) if !root?
    end

    def move(destination)
      raise 'Page is new' if new?
      raise 'Page is not current' unless current?
      destination = destination.to_s.cleanpath
      Page.check_path(destination)
      raise :already_exists.t(:page => destination) if Page.find(destination)
      with_hooks(:move, destination) { repository.move(self, destination) }
    end

    def delete
      raise 'Page is new' if new?
      raise 'Page is not current' unless current?
      with_hooks(:delete) { repository.delete(self) }
    end

    def diff(from, to)
      raise 'Page is new' if new?
      repository.diff(self, from, to)
    end

    def new?
      !tree_version
    end

    def name
      i = path.rindex('/')
      name = i ? path[i+1..-1] : path
    end

    def title
      attributes['title'] || (root? ? :root.t : name)
    end

    def extension
      i = path.index('.')
      i ? path[i+1..-1] : ''
    end

    def committed(path, tree_version)
      @path = path.freeze
      @tree_version = tree_version
      @version = @next_version = @previous_version =
        @parent = @children = @mime =
        @attributes = @saved_attributes =
        @content = @saved_content = nil
    end

    def attributes
      @attributes ||= deep_copy(saved_attributes)
    end

    def saved_attributes
      @saved_attributes ||= new? ? {} : repository.load_attributes(self)
    end

    def attributes=(a)
      a ||= {}
      if attributes != a
        @attributes = a
        @mime = nil
      end
    end

    def saved_content
      @saved_content ||= new? ? '' : repository.load_content(self)
    end

    def content
      @content ||= saved_content
    end

    def content=(c)
      if content != c
        @mime = nil
        @content = c
      end
    end

    def modified?
      content != saved_content || attributes != saved_attributes
    end

    def save
      raise 'Page is not current' unless current?
      raise :already_exists.t(:page => path) if new? && Page.find(path)
      with_hooks(:save) { repository.save(self) }
    end

    def mime
      @mime ||= detect_mime
    end

    def children
      @children ||= new? ? [] : repository.load_children(self).sort_by(&:name)
    end

    def self.default_mime
      mime = Config.mime.find {|m| m.include? '/'}
      mime ? MimeMagic.new(mime) : nil
    end

    private

    def self.check_path(path)
      raise :invalid_path.t if !valid_xml_chars?(path) || !(path.blank? || path =~ /^#{PATH_PATTERN}$/)
    end

    def detect_mime
      return MimeMagic.new(attributes['mime']) if attributes['mime']
      Config.mime.each do |mime|
        mime = if mime == 'extension'
                 MimeMagic.by_extension(extension)
               elsif %w(content magic).include?(mime)
                 if !new?
                   if content.blank?
                     children.empty? ? EMPTY_MIME : DIRECTORY_MIME
                   else
                     MimeMagic.by_magic(content)
                   end
                 end
               else
                 MimeMagic.new(mime)
               end
        return mime if mime
      end
    end

    def init_versions
      if !@version && @tree_version
        raise 'Page is new' if new?
        @previous_version, @version, @next_version = repository.load_version(self)
      end
    end

    def repository
      Repository.instance
    end

    def self.repository
      Repository.instance
    end
  end

  class Repository
    include Util
    extend Factory

    class << self
      attr_writer :instance
      def instance
        @instance ||= self[Config.repository.type].new(Config.repository[Config.repository.type])
      end
    end

    def transaction(&block)
      raise NotImplementedError
    end

    def commit(comment)
      raise NotImplementedError
    end

    def find_page(path, tree_version, current)
      raise NotImplementedError
    end

    def find_version(version)
      raise NotImplementedError
    end

    def load_history(page, skip, limit)
      raise NotImplementedError
    end

    def load_version(page)
      raise NotImplementedError
    end

    def load_children(page)
      raise NotImplementedError
    end

    def load_content(page)
      raise NotImplementedError
    end

    def load_attributes(page)
      raise NotImplementedError
    end

    def save(page)
      raise NotImplementedError
    end

    def move(page, destination)
      raise NotImplementedError
    end

    def delete(page)
      raise NotImplementedError
    end

    def diff(page, from, to)
      raise NotImplementedError
    end

    def short_version(version)
      version
    end
  end
end
