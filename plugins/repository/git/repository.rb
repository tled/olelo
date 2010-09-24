description 'Git repository backend'
require     'gitrb'

raise 'Newest gitrb version 0.2.7 is required. Please upgrade!' if !Gitrb.const_defined?('VERSION') || Gitrb::VERSION != '0.2.7'

class GitRepository < Repository
  CONTENT_EXT   = '.content'
  ATTRIBUTE_EXT = '.attributes'

  def initialize(config)
    logger = Plugin.current.logger
    logger.info "Opening git repository: #{config.path}"
    @shared_git = Gitrb::Repository.new(:path => config.path, :create => true,
                                        :bare => config.bare, :logger => logger)
    @current_transaction = {}
    @git = {}
  end

  # Access the underlying gitrb repository instance
  def git
    @git[Thread.current.object_id] ||= @shared_git.dup
  end

  # Start a transaction. Every thread has its own transaction.
  def transaction(&block)
    raise 'Transaction already running' if @current_transaction[Thread.current.object_id]
    @current_transaction[Thread.current.object_id] = []
    git.transaction(&block)
  ensure
    @current_transaction.delete(Thread.current.object_id)
  end

  # Commit a transaction. You must provide a commit comment.
  def commit(comment)
    user = User.current
    git.commit(comment, user && Gitrb::User.new(user.name, user.email))
    tree_version = commit_to_version(git.head)
    current_transaction.each {|f| f.call(tree_version) }
  end

  # Find a page by name and optional version.
  # The current flag determines if you want to browse the current repository tree.
  def find_page(path, tree_version, current)
    check_path(path)
    commit = !tree_version.blank? ? git.get_commit(tree_version.to_s) : git.head
    return nil if !commit
    object = commit.tree[path]
    return nil if !object
    Page.new(path, commit_to_version(commit), current)
  rescue
    nil
  end

  def find_version(version)
    commit_to_version(git.get_commit(version.to_s))
  rescue
    nil
  end

  def load_history(page, skip, limit)
    git.log(:max_count => limit, :skip => skip,
            :path => [page.path, page.path + ATTRIBUTE_EXT, page.path + CONTENT_EXT]).map do |c|
      commit_to_version(c)
    end
  end

  def load_version(page)
    commits = git.log(:max_count => 2, :start => page.tree_version, :path => [page.path, page.path + ATTRIBUTE_EXT, page.path + CONTENT_EXT])

    child = nil
    git.git_rev_list('--reverse', '--remove-empty', "#{commits[0]}..", '--', page.path, page.path + ATTRIBUTE_EXT, page.path + CONTENT_EXT) do |io|
      child = io.eof? ? nil : git.get_commit(git.set_encoding(io.readline).strip)
    end rescue nil # no error because pipe is closed intentionally

    # Deleted pages have next version (Issue #11)
    child = nil if child && !find_page(page.path, child.id, false)

    [commits[1] ? commit_to_version(commits[1]) : nil, # previous version
     commit_to_version(commits[0]),                    # current version
     child ? commit_to_version(child) : nil]           # next version
  end

  def load_children(page)
    object = git.get_commit(page.tree_version.to_s).tree[page.path]
    if object.type == :tree
      object.map do |name, child|
        Page.new(page.path/name, page.tree_version, page.current?) if !reserved_name?(name)
      end.compact
    else
      []
    end
  end

  def load_content(page)
    tree = git.get_commit(page.tree_version.to_s).tree
    object = tree[page.path]
    object = tree[page.path + CONTENT_EXT] if object && object.type == :tree
    if object
      content = object.data
      # Try to force utf-8 encoding and revert to old encoding if this doesn't work
      content.respond_to?(:try_encoding) ? content.try_encoding(Encoding::UTF_8) : content
    else
      ''
    end
  end

  def load_attributes(page)
    object = git.get_commit(page.tree_version.to_s).tree[page.path + ATTRIBUTE_EXT]
    object ? YAML.load(object.data) : {}
  end

  def save(page)
    path = page.path

    check_path(path)

    content = page.content
    content = content.read if content.respond_to? :read
    attributes = page.attributes.empty? ? nil : YAML.dump(page.attributes).sub(/\A\-\-\-\s*\n/s, '')

    # Convert blob parents to trees
    # to allow children
    names = path.split('/')
    names.pop
    parent = git.root
    names.each do |name|
      object = parent[name]
      break if !object
      if object.type == :blob
        parent.move(name, name + CONTENT_EXT)
        break
      end
      parent = object
    end

    object = git.root[path]
    if object
      if attributes
        git.root[path + ATTRIBUTE_EXT] = Gitrb::Blob.new(:data => attributes)
      else
        git.root.delete(path + ATTRIBUTE_EXT)
      end
      if object.type == :tree
        if content.blank?
          git.root.delete(path + CONTENT_EXT)
        else
          git.root[path + CONTENT_EXT] = Gitrb::Blob.new(:data => content)
        end
        collapse_empty_tree(path)
      else
        git.root[path] = Gitrb::Blob.new(:data => content)
      end
    else
      git.root[path] = Gitrb::Blob.new(:data => content)
      git.root[path + ATTRIBUTE_EXT] = Gitrb::Blob.new(:data => attributes) if attributes
    end

    current_transaction << proc {|tree_version| page.committed(path, tree_version) }
  end

  def move(page, destination)
    check_path(destination)
    git.root.move(page.path, destination)
    git.root.move(page.path + CONTENT_EXT, destination + CONTENT_EXT) if git.root[page.path + CONTENT_EXT]
    git.root.move(page.path + ATTRIBUTE_EXT, destination + ATTRIBUTE_EXT) if git.root[page.path + ATTRIBUTE_EXT]
    collapse_empty_tree(page.path/'..')
    current_transaction << proc {|tree_version| page.committed(destination, tree_version) }
  end

  def delete(page)
    git.root.delete(page.path)
    git.root.delete(page.path + CONTENT_EXT)
    git.root.delete(page.path + ATTRIBUTE_EXT)
    collapse_empty_tree(page.path/'..')
    current_transaction << proc { page.committed(page.path, nil) }
  end

  def diff(page, from, to)
    diff = git.diff(:from => from && from.to_s, :to => to.to_s,
                    :path => [page.path, page.path + CONTENT_EXT, page.path + ATTRIBUTE_EXT], :detect_renames => true)
    Olelo::Diff.new(diff.from && commit_to_version(diff.from), commit_to_version(diff.to), diff.patch)
  end

  def short_version(version)
    version[0..4]
  end

  def cleanup
    @git.delete(Thread.current.object_id)
  end

  def reserved_name?(name)
    name.ends_with?(ATTRIBUTE_EXT) || name.ends_with?(CONTENT_EXT)
  end

  private

  def check_path(path)
    raise :reserved_path.t if path.split('/').any? {|name| reserved_name?(name) }
  end

  def current_transaction
    @current_transaction[Thread.current.object_id] || raise('No transaction running')
  end

  def commit_to_version(commit)
    Olelo::Version.new(commit.id, Olelo::User.new(commit.author.name, commit.author.email),
                       commit.date, commit.message, commit.parents.map(&:id))
  end

  # If a tree consists only of tree/, tree.content and tree.attributes without
  # children, tree.content can be moved to tree ("collapsing").
  def collapse_empty_tree(path)
    if !path.blank? && git.root[path].empty? && git.root[path + CONTENT_EXT]
      git.root.move(path + CONTENT_EXT, path)
    end
  end
end

Repository.register :git, GitRepository

Application.after(:request) do
  Repository.instance.cleanup if GitRepository === Repository.instance
end
