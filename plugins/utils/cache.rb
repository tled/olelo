description  'Caching support'
dependencies 'utils/worker', 'utils/store'

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
  # * :defer   Deferred cache update
  def cache(key, opts = {}, &block)
    if opts[:disable] || !Config.production?
      yield(self)
    elsif @store.key?(key) && (!opts[:update] || opts[:defer])
      Worker.defer { update(key, opts, &block) } if opts[:update]
      @store[key]
    else
      update(key, opts, &block)
    end
  end

  def clear
    @store.clear
  end

  private

  def update(key, opts = {}, &block)
    content = block.call(self)
    @store[key] = content if !@disabled
    content
  end

  class<< self
    def store
      @store ||= Store.create(Config.cache_store)
    end

    def cache(*args, &block)
      Cache.new(store).cache(*args, &block)
    end
  end
end
