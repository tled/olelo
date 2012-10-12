require 'rugged'

class RuggedRepository < Repository
  CONTENT_EXT  = '.content'
  ATTRIBUTE_EXT = '.attributes'

  class Blob
    def initialize(git, content)
      @git = git
      @content = content
    end

    def type
      :blob
    end

    def filemode
      0100644
    end

    def save
      Rugged::Blob.create(@git, content)
    end
  end

  class Ref
    attr_reader :filemode, :type

    def initialize(git, entry)
      @oid = entry[:oid]
      @filemode = entry[:filemode]
      @type = entry[:type]
    end

    def save
      @oid
    end

    def lookup
      if type == :tree
        Tree.new(@git, @oid)
      else
        self
      end
    end
  end

  class Tree
    def initialize(git, oid)
      @git = git
      @entries = {}
      @oid = oid
      if oid
        tree = @git.lookup(oid)
        raise 'Not a tree' unless Rugged::Tree === tree
        tree.each {|entry| @entries[entry[:name]] = Ref.new(@git, entry) }
      end
    end

    def empty?
      @entries.empty?
    end

    def type
      :tree
    end

    def filemode
      0040000
    end

    def get(name)
      child = @entries[name]
      Ref === child ? @entries[name] = child.lookup : child
    end

    def [](path)
      name, path = path.split('/', 2)
      child = get(name)
      if path
        raise 'Find child in blob' unless child.type == :tree
        child[path]
      else
        child
      end
    end

    def []=(path, object)
      @oid = nil
      name, path = path.split('/', 2)
      child = get(name)
      if path
        child = @entries[name] = Tree.new(@git) unless child
        if child.type == :tree
          child[path] = object
        else
          raise 'Parent not found'
        end
      else
        @entries[name] = object
      end
    end

    def move(path, destination)
      self[destination] = delete(path)
    end

    def delete(path)
      @oid = nil
      name, path = path.split('/', 2)
      child = get(name)
      if path
        if child.type == :tree
          child.delete(path)
        else
          raise 'Object not found'
        end
      else
        raise 'Object not found' unless @entries.delete(name)
      end
    end

    def save
      return @oid if @oid
      builder = Rugged::TreeBuilder.new
      @entries.each do |name, entry|
        builder << { :type => entry.type, :filemode => entry.filemode, :oid => entry.save, :name => name }
      end
      builder.write(@git)
    end
  end

  class Transaction
    def initialize(git)
      @git = git
      @head = @git.head.target
      @tree = Tree.new(@git, @head.tree)
    end
  end

  def initialize(config)
    Olelo.logger.info "Opening git repository: #{config[:path]}"
    # Rugged::Repository.init_at('.', config[:bare])
    @git = Rugged::Repository.new(config[:path])
  end

  def transaction
    raise 'Transaction already running' if Thread.current[:olelo_rugged_tx]
    Thread.current[:olelo_rugged_tx] = Transaction.new(@git)
  ensure
    Thread.current[:olelo_rugged_tx] = nil
  end

  def set_content(path, content)
    check_path(path)
    content = content.read if content.respond_to? :read
    expand_tree(path)
    if current_tree[path].type == :tree
      if content.blank?
        current_tree.delete(path + CONTENT_EXT)
      else
        current_tree[path + CONTENT_EXT] = Blob.new(@git, content)
      end
      collapse_empty_tree(path)
    else
      current_tree[path] = Blob.new(@git, content)
    end
  end

  def set_attributes(path, attributes)
    check_path(path)
    attributes = attributes.blank? ? nil : YAML.dump(attributes).sub(/\A\-\-\-\s*\n/s, '')
    expand_tree(path)
    if attributes
      current_tree[path + ATTRIBUTE_EXT] = Blob.new(@git, attributes)
    else
      current_tree.delete(path + ATTRIBUTE_EXT)
    end
  end

  def move(path, destination)
    check_path(destination)
    current_tree.move(path, destination)
    current_tree.move(path + CONTENT_EXT, destination + CONTENT_EXT) if current_tree[path + CONTENT_EXT]
    current_tree.move(path + ATTRIBUTE_EXT, destination + ATTRIBUTE_EXT) if current_tree[path + ATTRIBUTE_EXT]
    collapse_empty_tree(path/'..')
  end

  def delete(path)
    current_tree.delete(path)
    current_tree.delete(path + CONTENT_EXT) if current_tree[path + CONTENT_EXT]
    current_tree.delete(path + ATTRIBUTE_EXT) if current_tree[path + ATTRIBUTE_EXT]
    collapse_empty_tree(path/'..')
  end

  def commit(comment)
    user = User.current
    raise 'Concurrent transactions' current_transaction.head != @git.head.target

    author = {:email => user.email, :name => user.name, :time => Time.now }
    commit = Rugged::Commit.create(@git,
                                   :author => author,
                                   :message => comment,
                                   :committer => author,
                                   :parents => [current_transaction.head],
                                   :tree => current_tree.save)

    raise 'Concurrent transactions' current_transaction.head != @git.head.target
    @git.head.target = commit

    commit_to_version(@git.lookup(commit))
  end

  def path_exists?(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    has_path?(commit.tree, path)
  end

  def get_version(version = nil)
    version ||= @git.head.target
    version = version.to_s
    commit_to_version(@git.lookup(version))
  end

  def get_history(path, skip = nil, limit = nil)
    commits = []
    walker = Rugged::Walker.new(@git)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(@git.head.target)
    walker.each do |c|
      if has_path?(c.tree, path)
        if skip > 0
          skip -= 1
        else
          commits << c
          break if limit && commits.size >= limit
        end
      end
    end
    commits.map {|c| commit_to_version(c) }
  end

  def get_path_version(path, version)
    version ||= @git.head.target
    version = version.to_s

    commits = []
    walker = Rugged::Walker.new(@git)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(version)
    walker.each do |c|
      if has_path?(c.tree, path)
        commits << c
        break if commits.size == 2
      end
    end

    succ = nil
    if version != @git.head.target
      newer = nil
      walker.reset
      walker.sorting(Rugged::SORT_TOPO)
      walker.push(@git.head.target)
      walker.each do |c|
        if has_path?(c.tree, path)
          if c == commits[0]
            succ = newer
            break
          end
          newer = c
        end
      end
    end

    [commit_to_version(commits[1]), # previous version
     commit_to_version(commits[0]), # current version
     commit_to_version(succ)] # next version
  end

  def get_children(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    object = object_by_path(commit.tree, path)
    Rugged::Tree === object ? object.map {|e| e[:name] }.reject {|name| reserved_name?(name) } : []
  end

  def get_content(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    object = object_by_path(commit.tree, path)
    object = object_by_path(object, CONTENT_EXT) if Rugged::Tree === object
    Rugged::Blob === object ? object.content : ''
  end

  def get_attributes(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    path += ATTRIBUTE_EXT
    object = object_by_path(commit.tree, path)
    object ? YAML.load(object.content) : {}
  end

  def diff(path, from, to)
    raise NotImplementedError
  end

  def short_version(version)
    version[0..4]
  end

  private

  def check_path(path)
    raise :reserved_path.t if path.split('/').any? {|name| reserved_name?(name) }
  end

  def has_path?(tree, path)
    return true if path.blank?
    (tree.path(path) rescue nil) ||
      (tree.path(path + ATTRIBUTE_EXT) rescue nil) ||
      (tree.path(path + CONTENT_EXT) rescue nil)
  end

  def object_by_path(tree, path)
    return tree if path.blank?
    ref = tree.path(path)
    @git.lookup(ref[:oid])
  rescue Rugged::IndexerError
    nil
  end

  def reserved_name?(name)
    name.ends_with?(ATTRIBUTE_EXT) || name.ends_with?(CONTENT_EXT)
  end

  def commit_to_version(commit)
    commit && Version.new(commit.oid, User.new(commit.author[:name], commit.author[:email]),
                          Time.at(commit.time), commit.message, commit.parents.map(&:oid), commit.oid == @git.head.target)
  end

  def current_transaction
    Thread.current[:olelo_rugged_tx] || raise('No transaction running')
  end

  def current_tree
    current_transaction.tree
  end

  # Convert blob parents to trees
  # to allow children
  def expand_tree(path)
    names = path.split('/')
    names.pop
    parent = current_tree
    names.each do |name|
      object = parent[name]
      break if !object
      if object.type == :blob
        parent.move(name, name + CONTENT_EXT)
        break
      end
      parent = object
    end
  end

  # If a tree consists only of tree/, tree.content and tree.attributes without
  # children, tree.content can be moved to tree ("collapsing").
  def collapse_empty_tree(path)
    if !path.blank? && current_tree[path].empty? && current_tree[path + CONTENT_EXT]
      current_tree.move(path + CONTENT_EXT, path)
    end
  end
end

Repository.register :rugged, RuggedRepository
