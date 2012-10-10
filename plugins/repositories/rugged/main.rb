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
    path.blank? ? true : commit.tree[path] != nil
  end

  def get_version(version = nil)
    version ||= @git.head.target
    version = version.to_s
    commit_to_version(@git.lookup(version))
  end

  def get_history(path, skip = nil, limit = nil)
    raise NotImplementedError
  end

  def get_path_version(path, version)
    #raise NotImplementedError
    version ||= @git.head.target
    version = version.to_s

    commits = []
    walker = Rugged::Walker.new(@git)
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(version)
    walker.each do |c|
      if path.blank? || c.tree[path] || c.tree[path + CONTENT_EXT] || c.tree[path + ATTRIBUTE_EXT]
        commits << c
        break if commits.size == 2
      end
    end

    succ, newer = nil, nil
    walker.reset
    walker.sorting(Rugged::SORT_TOPO)
    walker.push(@git.head.target)
    walker.each do |c|
      if path.blank? || c.tree[path] || c.tree[path + CONTENT_EXT] || c.tree[path + ATTRIBUTE_EXT]
        if c == commits[0]
          succ = newer
          break
        end
        newer = c
      end
    end

    [commit_to_version(commits[1]), # previous version
     commit_to_version(commits[0]), # current version
     commit_to_version(succ)] # next version
  end

  def get_children(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    if path.blank?
      commit.tree
    else
      return [] unless ref = commit.tree[path]
      @git.lookup(ref[:oid])
    end.map {|e| e[:name] }.reject {|name| reserved_name?(name) }
  end

  def get_content(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    path += CONTENT_EXT if path.blank? || commit.tree[path][:type] == :tree
    return '' unless ref = commit.tree[path]
    @git.lookup(ref[:oid]).content
  end

  def get_attributes(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    path += ATTRIBUTE_EXT
    return {} unless ref = commit.tree[path]
    YAML.load(@git.lookup(ref[:oid]).content)
  end

  def diff(path, from, to)
    raise NotImplementedError
  end

  def short_version(version)
    version[0..4]
  end

  private

  def reserved_name?(name)
    name.ends_with?(ATTRIBUTE_EXT) || name.ends_with?(CONTENT_EXT)
  end

  def commit_to_version(commit)
    commit && Version.new(commit.oid, User.new(commit.author[:name], commit.author[:email]),
                          Time.at(commit.time), commit.message, commit.parents.map(&:oid), commit.oid == @git.head.target)
  end
end

Repository.register :rugged, RuggedRepository
