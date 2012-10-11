require 'rugged'

class RuggedRepository < Repository
  CONTENT_EXT  = '.content'
  ATTRIBUTE_EXT = '.attributes'

  def initialize(config)
    Olelo.logger.info "Opening git repository: #{config[:path]}"
    # Rugged::Repository.init_at('.', config[:bare])
    @git = Rugged::Repository.new(config[:path])
  end

  def transaction
    raise NotImplementedError
  end

  def set_content(path, content)
    raise NotImplementedError
  end

  def set_attributes(path, attributes)
    raise NotImplementedError
  end

  def move(path, destination)
    raise NotImplementedError
  end

  def delete(path)
    raise NotImplementedError
  end

  def commit(comment)
    raise NotImplementedError
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
end

Repository.register :rugged, RuggedRepository
