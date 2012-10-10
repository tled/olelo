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
    [commit_to_version(@git.lookup(version)),
     commit_to_version(@git.lookup(version)),
     commit_to_version(@git.lookup(version))]
  end

  def get_children(path, version)
    puts "get_children: #{path.inspect}"
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    if path.blank?
      commit.tree
    else
      if ref = commit.tree[path]
        @git.lookup(ref[:oid])
      else
        []
      end
    end.map {|e| e[:name] }.reject {|name| reserved_name?(name) }
  end

  def get_content(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    path += CONTENT_EXT if path.blank? || commit.tree[path][:type] == :tree
    if ref = commit.tree[path]
      @git.lookup(ref[:oid]).content
    else
      ''
    end
  end

  def get_attributes(path, version)
    commit = @git.lookup(version.to_s)
    raise 'Not a commit' unless Rugged::Commit === commit
    path += ATTRIBUTE_EXT
    if ref = commit.tree[path]
      YAML.load(@git.lookup(ref[:oid]).content)
    else
      {}
    end
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
                          Time.new(commit.time), commit.message, commit.parents.map(&:oid), commit == @git.head)
  end
end

Repository.register :rugged, RuggedRepository
