description  'Caching support'
dependencies 'utils/worker', 'utils/store'

class Cache
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
  # * :defer   Deferred cache update
  def cache(key, options = {}, &block)
    return yield(self) if options[:disable] || !Config['production']

    # Warning: don't change this. This must be thread safe!
    if options[:update]
      if options[:defer] && (value = @store[key] || @store.key?(key)) # Check key? because value could be nil
        Worker.defer { update(key, options, &block) }
        return value
      end
    else
      return value if value = @store[key] || @store.key?(key) # Check key? because value could be nil
    end
    update(key, options, &block)
  end

  def clear
    @store.clear
  end

  private

  def update(key, options = {}, &block)
    content = block.call(self)
    @store[key] = content if !@disabled
    content
  end

  class<< self
    def store
      @store ||= Store.create(Config['cache_store'])
    end

    def cache(*args, &block)
      Cache.new(store).cache(*args, &block)
    end
  end
end

Olelo::Cache = Cache
