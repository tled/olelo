module Olelo
  module Templates
    class << self
      attr_reader :cache
      attr_accessor :loader

      def enable_caching
        @cache = {}
      end

      def with_caching(id)
        return cache[id] if cache && cache[id]
        template = yield
        cache[id] = template if cache
        template
      end
    end

    def render(name, options = {}, &block)
      locals = options.delete(:locals) || {}
      name = "#{name}.slim"
      path = Templates.loader.context.to_s/name
      id = [path, options.map {|x| x}].flatten.join('-')
      template = Templates.with_caching(id) do
        Slim::Template.new(path, options) { Templates.loader.load(name) }
      end
      template.render(self, locals, &block).html_safe
    end
  end
end
