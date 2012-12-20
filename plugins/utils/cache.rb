description  'Caching support'
dependencies 'utils/worker'
require 'moneta'

class Cache
  def initialize(store = nil)
    @store = store || default_store
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
      if options[:defer] && ((value = @store[key]) || @store.key?(key)) # Check key? because value could be nil
        Worker.defer { update(key, options, &block) }
        return value
      end
    else
      return value if (value = @store[key]) || @store.key?(key) # Check key? because value could be nil
    end
    update(key, options, &block)
  end

  def clear
    @store.clear
  end

  private

  def update(key, options = {}, &block)
    disabler = Disabler.new
    content = block.call(disabler)
    @store[key] = content unless disabler.disabled?
    content
  end

  def default_store
    @@store ||=
      begin
        type = Config['cache_store.type'].to_sym
        config = Config['cache_store'][type].to_hash
        # FIXME: Deprecated :file store config
        if type == :file
          puts 'WARNING: You are using the deprecated \'file\' store as cache_store in your configuration.'
          type = :HashFile
          config[:dir] = config.delete(:root)
        end
        Moneta.new(type, config)
      end
  end

  class Disabler
    attr_reader? :disabled
    def initialize; @disabled = false end
    def disable!; @disabled = true end
  end
end

module ::Olelo::Util
  def cache(key, options = {}, &block)
    Cache.new.cache(key, options = {}, &block)
  end
end

Olelo::Cache = Cache
