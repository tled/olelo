module Olelo
  # Olelo plugin system
  class Plugin
    include Util
    include Hooks

    has_around_hooks :load

    @plugins = {}
    @failed = []
    @disabled = []
    @dir = ''
    @logger = nil

    class<< self
      attr_accessor :dir, :logger, :disabled

      # Get failed plugins
      attr_reader :failed

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

      # Start plugins
      # @return [void]
      def start
        @plugins.each_value {|plugin| plugin.start }
      end

      # Load plugins by name
      #
      # @param list List of plugin names to load
      # @return [Boolean] true if every plugin was loaded
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
      #
      # @param [String] plugin name
      # @return [Boolean] true if enabled
      #
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

    # Virtual filesystem used to load plugin assets
    def virtual_fs
      VirtualFS::Union.new(VirtualFS::Embedded.new(file),
                           VirtualFS::Native.new(File.dirname(file)))
    end

    # Start the plugin by calling the {#setup} method
    #
    # @return [Boolean] true for success
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

    # Load specified plugins and fail with LoadError if dependencies are missing
    #
    # @param list List of plugin names to load
    # @return List of dependencies (plugin names)
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
