module Olelo
  # Olelo plugin system
  class Plugin
    include Util
    include Hooks

    @plugins = {}
    @failed = []
    @disabled = []
    @dir = ''
    @logger = nil

    class<< self
      attr_accessor :dir, :logger, :disabled

      # Current plugin
      def current(level = 0)
        last = nil
        caller.each do |line|
          if line =~ %r{^#{@dir}/(.+?)\.rb} && $1 != last
            last = $1
            level -= 1
            return @plugins[$1] if level < 0
          end
        end
        nil
      end

      # Get all plugins
      def plugins
        @plugins.values
      end

      # Get failed plugins
      def failed
        @failed
      end

      # Start plugins
      def start
        @plugins.each_value {|plugin| plugin.start }
      end

      # Load plugins by name and return a boolean for success
      def load(*list)
        files = list.map do |name|
          Dir[File.join(@dir, '**', "#{name.cleanpath}.rb")]
        end.flatten
        return false if files.empty?
        files.inject(true) do |result,file|
          name = file[(@dir.size+1)..-4]
          if @plugins.include?(name)
	    result
	  elsif @failed.include?(name) || !enabled?(name)
	    false
	  else
            begin
	      plugin = new(name, file, logger)
              plugin.with_hooks :load do
                @plugins[name] = plugin
                plugin.instance_eval(File.read(file), file)
                logger.debug("Plugin #{name} successfully loaded")
              end
            rescue Exception => ex
              @failed << name
              if LoadError === ex
                logger.warn "Plugin #{name} could not be loaded due to: #{ex.message} (Missing gem?)"
              else
                logger.error "Plugin #{name} could not be loaded due to: #{ex.message}"
                logger.error ex
              end
              @plugins.delete(name)
              false
            end
	  end
        end
      end

      # Check if plugin is enabled
      def enabled?(name)
        paths = name.split(File::SEPARATOR)
        paths.inject(nil) do |path, x|
          path = path ? File.join(path, x) : x
          return false if disabled.include?(path)
          path
        end
        true
      end
    end

    attr_reader :name, :file
    attr_reader? :started
    attr_setter :description, :logger

    def initialize(name, file, logger)
      @name = name
      @file = file
      @logger = logger
      @started = false
    end

    # Start the plugin
    def start
      return true if @started
      setup if respond_to?(:setup)
      logger.debug "Plugin #{name} successfully started"
      @started = true
    rescue Exception => ex
      logger.error "Plugin #{name} failed to start due to: #{ex.message}"
      logger.error ex
      false
    end

    # Load specified plugins and fail if
    # dependencies are missing.
    def dependencies(*list)
      @dependencies ||= []
      @dependencies += list
      list.each do |dep|
        raise(LoadError, "Could not load dependency #{dep} for #{name}") if !Plugin.load(dep)
      end
      @dependencies
    end

    private_class_method :new
  end
end
