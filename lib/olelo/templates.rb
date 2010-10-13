module Olelo
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true, :escape_html => true }.freeze

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
      name = "#{name}.haml"
      path = Templates.loader.context.to_s/name
      haml_options = HAML_OPTIONS.merge(options).merge(:filename => path)
      id = [path, haml_options.map {|x| x}].flatten.join('-')
      engine = Templates.with_caching(id) do
        Haml::Engine.new(Templates.loader.load(name), haml_options)
      end
      engine.render(self, locals, &block)
    end
  end
end
