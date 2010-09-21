description  'Caching support'
dependencies 'utils/worker'

class Olelo::Cache
  def initialize(store)
    @store = store
    @disabled = false
  end

  def disable!
    @disabled = true
  end

  # Block around cacheable return value identified by a <i>key</i>.
  # The following options can be specified:
  # * :disable Disable caching
  # * :update  Force cache update
  # * :marshal Marshal data before storing
  # * :defer   Deferred cache update
  def cache(key, opts = {}, &block)
    key = Util.md5(key)
    if opts[:disable] || !Config.production?
      yield(self)
    elsif @store.include?(key) && (!opts[:update] || opts[:defer])
      Worker.defer { update(key, opts, &block) } if opts[:update]
      opts[:marshal] ? Marshal.load(@store[key]) : @store[key]
    else
      update(key, opts, &block)
    end
  end

  def update(key, opts = {}, &block)
    content = block.call(self)
    @store[key] = opts[:marshal] ? Marshal.dump(content) : content if !@disabled
    content
  end

  class<< self
    def global_store
      @global_store ||= FileStore.new(File.join(Config.tmp_path, 'cache'))
    end

    def cache(*args, &block)
      Cache.new(global_store).cache(*args, &block)
    end
  end

  # File based cache
  class FileStore
    attr_reader :root

    # Cache constructor which specifies a <i>root</i> directory
    def initialize(root)
      @root = root
      FileUtils.mkdir_p root, :mode => 0755
    end

    # Exists the entry with <i>key</i>
    def include?(key)
      File.exist?(cache_path(key))
    end

    # Read entry with <i>key</i>
    def [](key)
      File.read(cache_path(key))
    rescue Errno::ENOENT
      nil
    end

    # Write entry <i>content</i> with <i>key</i>.
    def []=(key, content)
      temp_file = File.join(root, ['tmp', $$, Thread.current.object_id].join('-'))
      File.open(temp_file, 'wb') do |dest|
        if content.respond_to? :to_str
          dest.write(content.to_str)
        else
          content.each {|s| dest.write(s) }
        end
      end

      path = cache_path(key)
      File.unlink path if File.exist?(path)
      FileUtils.mkdir_p File.dirname(path), :mode => 0755
      FileUtils.mv temp_file, path
    rescue
      File.unlink temp_file rescue nil
    ensure
      content
    end

    # Delete entry with <i>key</i>
    def delete(key)
      File.unlink cache_path(key)
    rescue Errno::ENOENT
    end

    protected

    def cache_path(key)
      File.join(root, key[0..1], key[2..-1])
    end
  end
end
