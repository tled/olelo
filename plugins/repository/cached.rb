description  'Repository lookup cache'
dependencies 'utils/store'
require      'delegate'

class CachedRepository < DelegateClass(Repository)
  def initialize(config)
    super(Repository[config[:backend]].new(Config.repository[config[:backend]]))
    @cache = Store.create(config[:store])
    @transaction = {}
  end

  # @override
  def transaction(&block)
    @transaction[Thread.current.object_id] = true
    super
  ensure
    @cache.clear
    @transaction.delete(Thread.current.object_id)
  end

  # @override
  def path_exists?(path, version)
    if @transaction[Thread.current.object_id]
      super
    else
      @cache["p-#{path}-#{version}"] ||= super
    end
  end

  # @override
  def get_path_version(path, version)
    if @transaction[Thread.current.object_id]
      super
    else
      @cache["v-#{path}-#{version}"] ||= super
    end
  end
end

Repository.register :cached, CachedRepository
