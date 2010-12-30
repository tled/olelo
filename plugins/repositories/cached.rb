description  'Repository lookup cache'
dependencies 'utils/store'
require 'delegate'

class CachedRepository < DelegateClass(Repository)
  def initialize(config)
    super(Repository[config[:backend]].new(Config['repository'][config[:backend]]))
    @cache = Utils::Store.create(config[:store])
  end

  alias uncached_get_version get_version

  # @override
  def get_version(version)
    validate_cache
    @cache["v-#{version}"] ||= super
  end

  # @override
  def path_exists?(path, version)
    validate_cache
    @cache["p-#{path}-#{version}"] ||= super
  end

  # @override
  def get_path_version(path, version)
    validate_cache
    @cache["pv-#{path}-#{version}"] ||= super
  end

  private

  def validate_cache
    head = uncached_get_version(nil).try(:id)
    if @cache['head'] != head
      @cache.clear
      @cache['head'] = head
    end
  end
end

Repository.register :cached, CachedRepository
