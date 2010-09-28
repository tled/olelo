module Olelo
  class Initializer
    include Util

    def self.init(logger)
      @instance ||= Initializer.new(logger)
    end

    def initialize(logger)
      @logger = logger
      init_locale
      init_templates
      init_plugins
      init_themes
      init_routes
      init_custom
    end

    private

    def init_locale
      Locale.locale = Config.locale
      Locale.load(File.join(File.dirname(__FILE__), 'locale.yml'))
    end

    def init_templates
      Templates.enable_caching if Config.production?
      Templates.loader = Class.new do
        def context
          Plugin.current.try(:name)
        end

        def load(name)
          VirtualFS::Union.new(Plugin.current.try(:virtual_fs),
                               VirtualFS::Native.new(Config.views_path)).read(name)
        end
      end.new
    end

    def init_plugins
      # Load locales for loaded plugins
      Plugin.after(:load) { Locale.load(File.join(File.dirname(file), 'locale.yml')) }

      # Configure plugin system
      Plugin.logger = @logger
      Plugin.disabled = Config.disabled_plugins.to_a
      Plugin.dir = Config.plugins_path

      # Load all plugins
      Plugin.load('*')
      Plugin.start
    end

    def init_themes
      default = File.basename(File.readlink(File.join(Config.themes_path, 'default')))
      Application.theme_links = Dir.glob(File.join(Config.themes_path, '*', 'style.css')).map do |file|
        name = File.basename(File.dirname(file))
        path = Config.base_path + "static/themes/#{name}/style.css?#{File.mtime(file).to_i}"
        %{<link rel="#{name == default ? '' : 'alternate '}stylesheet"
          href="#{escape_html path}" type="text/css" title="#{escape_html name}"/>}.unindent if name != 'default'
      end.compact.join("\n")
    end

    def init_routes
      Application.reserved_paths = Application.router.map do |method, router|
        router.head.map {|name, pattern, keys| pattern }
      end.flatten
      Application.router.each do |method, router|
        @logger.debug method
        router.each do |name, pattern, keys|
          @logger.debug "#{name} -> #{pattern.inspect}"
        end
      end if @logger.debug?
    end

    def init_custom
      Dir[File.join(Config.initializers_path, '*.rb')].sort_by do |f|
        File.basename(f)
      end.each do |f|
        @logger.debug "Running custom initializer #{f}"
	instance_eval(File.read(f), f)
      end
    end
  end
end
