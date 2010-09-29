module Olelo
  # Wiki page object
  class Page
    include Util
    include Hooks
    include Attributes

    attributes do
      string  :title
      boolean :no_title
      string  :description
      string :mime do
        Hash[*Config.mime_suggestions.map do |mime|
               comment = MimeMagic.new(mime).comment
               [mime, comment.blank? ? mime : "#{comment} (#{mime})"]
             end.flatten]
      end
    end

    # Pattern for valid paths
    # @api public
    PATH_PATTERN = '[^\s](?:.*[^\s]+)?'

    # Mime type for empty page
    # @api public
    EMPTY_MIME = MimeMagic.new('application/x-empty')

    # Mime type for directory
    # @api public
    DIRECTORY_MIME = MimeMagic.new('inode/directory')

    attr_reader :path, :tree_version
    attr_reader? :current

    @current_transaction = {}

    def initialize(path, tree_version = nil, current = true)
      @path = path.to_s.cleanpath.freeze
      @tree_version = tree_version
      @current = current
      Page.check_path(path)
    end

    def self.transaction(&block)
      raise 'Transaction already running' if @current_transaction[Thread.current.object_id]
      @current_transaction[Thread.current.object_id] = []
      repository.transaction(&block)
    ensure
      @current_transaction.delete(Thread.current.object_id)
    end

    def self.current_transaction
      @current_transaction[Thread.current.object_id] || raise('No transaction running')
    end

    def self.commit(comment)
      tree_version = repository.commit(comment)
      current_transaction.each {|proc| proc.call(tree_version) }
    end

    # Throws exceptions if access denied, returns nil if not found
    def self.find(path, version = nil, current = nil)
      path = path.to_s.cleanpath
      check_path(path)
      tree_version = repository.get_version(version)
      if repository.path_exists?(path, tree_version)
        Page.new(path, tree_version, current.nil? ? version.blank? : current)
      end
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
      repository.get_history(path, skip, limit)
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
      with_hooks(:move, destination) { repository.move(path, destination) }
      after_transaction {|tree_version| update(destination, tree_version) }
    end

    def delete
      raise 'Page is new' if new?
      raise 'Page is not current' unless current?
      with_hooks(:delete) { repository.delete(path) }
      after_transaction {|tree_version| update(path, nil) }
    end

    def diff(from, to)
      raise 'Page is new' if new?
      repository.diff(path, from, to)
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

    def attributes
      @attributes ||= deep_copy(saved_attributes)
    end

    def saved_attributes
      @saved_attributes ||= new? ? {} : repository.get_attributes(path, tree_version)
    end

    def attributes=(a)
      a ||= {}
      if attributes != a
        @attributes = a
        @mime = nil
      end
    end

    def saved_content
      @saved_content ||= new? ? '' : repository.get_content(path, tree_version)
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
      with_hooks(:save) do
        repository.set_content(path, content)
        repository.set_attributes(path, attributes)
      end
      after_transaction {|tree_version| update(path, tree_version) }
    end

    def mime
      @mime ||= detect_mime
    end

    def children
      @children ||=
        if new?
          []
        else
          repository.get_children(path, tree_version).sort.map do |name|
            Page.new(path/name, tree_version, current?)
          end
        end
    end

    def self.default_mime
      mime = Config.mime.find {|m| m.include? '/'}
      mime ? MimeMagic.new(mime) : nil
    end

    private

    def update(path, tree_version)
      @path = path.freeze
      @tree_version = tree_version
      @version = @next_version = @previous_version =
        @parent = @children = @mime =
        @attributes = @saved_attributes =
        @content = @saved_content = nil
    end

    def after_transaction(&block)
      Page.current_transaction << block
    end

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
        @previous_version, @version, @next_version = repository.get_path_version(path, tree_version)
      end
    end

    def repository
      Repository.instance
    end

    def self.repository
      Repository.instance
    end
  end
end
