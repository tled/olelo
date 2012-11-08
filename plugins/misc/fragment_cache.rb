description 'Cache page fragments'
dependencies 'utils/cache'

class ::Olelo::Application
  def cache_id
    @cache_id ||= page ? "#{page.path}-#{page.etag}-#{build_query(params)}" : "#{request.path_info}-#{build_query(params)}"
  end

  redefine_method :menu do |name|
    Cache.cache("menu-#{name}-#{cache_id}", update: no_cache?) do |cache|
      super(name)
    end
  end

  redefine_method :head do
    Cache.cache("head-#{cache_id}", update: no_cache?) do |cache|
      super()
    end
  end

  redefine_method :footer do |content = nil, &block|
    # FIXME: Use block instead of block_given?, block_given? returns always false. Is this a ruby issue?
    if block || content
      super(content, &block)
    else
      Cache.cache("footer-#{cache_id}", update: no_cache?) do |cache|
        super()
      end
    end
  end
end
