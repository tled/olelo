description  'Repository lookup cache'
dependencies 'utils/store'
require      'delegate'

class CachedRepository < DelegateClass(Repository)
  def initialize(config)
    super(Repository[config.backend].new(Config.repository[config.backend]))
    @cache = Store.create(config.store)
    @in_transaction = {}
  end

  def transaction(&block)
    @in_transaction[Thread.current.object_id] = true
    super
  ensure
    @cache.clear
    @in_transaction.delete(Thread.current.object_id)
  end

  def find_page(path, tree_version, current)
    if @in_transaction[Thread.current.object_id]
      super
    else
      id = "page-#{path}-#{tree_version}"
      tree_version = @cache[id]
      if tree_version
        Page.new(path, tree_version, current)
      else
        page = super
        @cache[id] = page.tree_version if page
        page
      end
    end
  end

  def load_version(page)
    if @in_transaction[Thread.current.object_id]
      super
    else
      @cache["version-#{page.path}-#{page.tree_version}"] ||= super
    end
  end
end

Repository.register :cached, CachedRepository
