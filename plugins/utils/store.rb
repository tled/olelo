description 'Key/value store'
require 'delegate'

# Simple interface to key/value stores with Hash-like interface.
#
# Store supports a subset of the Moneta interface,
# Moneta can be used as a drop-in replacement.
# It is recommended to wrap the moneta store in a Olelo::Store::Delegated
# to only expose the Olelo::Store interface.
class Olelo::Store
  extend Factory

  # Exists the entry with <i>key</i>
  def key?(key)
    raise NotImplementedError
  end

  # Read entry with <i>key</i>. Return nil if the key doesn't exist
  def [](key)
    raise NotImplementedError
  end

  # Write entry <i>value</i> with <i>key</i>.
  def []=(key, value)
    raise NotImplementedError
  end

  # Delete the <i>key</i> from the store and return the current value.
  def delete(key)
    raise NotImplementedError
  end

  # Clear all keys in this store
  def clear
    raise NotImplementedError
  end

  protected

  # Serialize value
  def serialize(value)
    Marshal.dump(value)
  end

  # Deserialize value
  def deserialize(value)
    value && Marshal.load(value)
  end

  # Create store instance
  def self.create(config)
    self[config[:type]].new(config[config[:type]])
  end

  # Delegated store
  Delegated = DelegateClass(Store)

  # Synchronized store
  def self.Synchronized(type)
    klass = Class.new
    klass.class_eval %{
      def initialize(config)
        @store = #{type.name}.new(config)
        @lock = Mutex.new
      end

      def method_missing(*args)
        @lock.synchronize { @store.send(*args) }
      end
    }
    klass
  end

  # Memory based store (uses hash)
  class Memory < Delegated
    def initialize(config)
      super({})
    end
  end

  register :memory, Memory

  # Memcached client
  class Memcached < Delegated
    def initialize(config)
      super(Store::Synchronized(Native).new(config))
    rescue LoadError
      super(Ruby.new(config))
    end

    # Uses the memcached gem
    class Native < Store
      include Util

      def initialize(config)
        require 'memcached'
        @server = ::Memcached.new(config[:server], :prefix_key => (config[:prefix] rescue nil))
      end

      def key?(key)
        @server.get(md5(key), false)
        true
      rescue ::Memcached::NotFound
        false
      end

      def [](key)
        @server.get(md5(key))
      rescue ::Memcached::NotFound
      end

      def []=(key, value)
        @server.set(md5(key), value)
        value
      end

      def delete(key)
        key = md5(key)
        value = @server.get(key)
        @server.delete(key)
        value
      rescue ::Memcached::NotFound
      end

      def clear
        @server.flush
      end
    end

    # Uses the memcache-client gem
    class Ruby < Store
      include Util

      def initialize(config)
        require 'memcache'
        @server = ::MemCache.new(config[:server], :namespace => (config[:prefix] rescue nil))
      end

      def key?(key)
        !@server.get(md5(key)).nil?
      end

      def [](key)
        deserialize(@server.get(md5(key)))
      end

      def []=(key, value)
        @server.set(md5(key), serialize(value))
        value
      end

      def delete(key)
        key = md5(key)
        value = deserialize(@server.get(key))
        @server.delete(key)
        value
      end

      def clear
        @server.flush_all
      end
    end
  end

  register :memcached, Memcached

  # PStore based store
  class PStore < Store
    def initialize(config)
      require 'pstore'
      FileUtils.mkpath(::File.dirname(config[:file]))
      @store = ::PStore.new(config[:file])
    end

    def key?(key)
      @store.transaction(true) { @store.root?(key) }
    end

    def [](key)
      @store.transaction(true) { @store[key] }
    end

    def []=(key, value)
      @store.transaction { @store[key] = value }
    end

    def delete(key)
      @store.transaction { @store.delete(key) }
    end

    def clear
      @store.transaction do
        @store.roots.each do |key|
          @store.delete(key)
        end
      end
    end
  end

  register :pstore, Synchronized(PStore)

  # File based store
  class File < Store
    def initialize(config)
      @root = config[:root]
    end

    def key?(key)
      ::File.exist?(store_path(key))
    end

    def [](key)
      deserialize(::File.read(store_path(key)))
    rescue Errno::ENOENT
    end

    def []=(key, value)
      temp_file = ::File.join(@root, "value-#{$$}-#{Thread.current.object_id}")
      FileUtils.mkpath(@root)
      ::File.open(temp_file, 'wb') {|file| file.write(serialize(value)) }
      path = store_path(key)
      FileUtils.mkpath(::File.dirname(path))
      ::File.unlink(path) if ::File.exist?(path)
      FileUtils.mv(temp_file, path)
    rescue
      ::File.unlink(temp_file) rescue nil
    ensure
      value
    end

    def delete(key)
      value = self[key]
      ::File.unlink(store_path(key))
      value
    rescue Errno::ENOENT
    end

    def clear
      temp_dir = "#{@root}-#{$$}-#{Thread.current.object_id}"
      FileUtils.mv(@root, temp_dir)
      FileUtils.rm_rf(temp_dir)
    rescue Errno::ENOENT
    end

    protected

    def store_path(key)
      key = Util.md5(key)
      ::File.join(@root, key[0..1], key[2..-1])
    end
  end

  register :file, File
end
