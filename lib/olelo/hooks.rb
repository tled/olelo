module Olelo
  module ErrorHandler
    def self.included(base)
      base.extend(ClassMethods)
    end

    def handle_error(error)
      type = error.class
      while type
        self.class.error_handler[type].to_a.sort_by(&:first).each {|x| send(x.last, error) }
        type = type.superclass
      end
    end

    module ClassMethods
      def error_handler
        @error_handler ||= {}
      end

      def error(error, priority = 99, &block)
        handler = (error_handler[error] ||= [])
        method = "ERROR #{error} #{handler.size}"
        define_method(method, &block)
        handler << [priority, method]
      end
    end
  end

  # Include this module to add hook support to your class.
  # The class will be extended with {ClassMethods} which
  # provides the methods to register hooks.
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Execute block surrounded with hooks
    #
    # It calls the hooks that were registered by {ClassMethods#before} and {ClassMethods#after} and
    # returns an array consisting of the before hook results,
    # the block result and the after hook results.
    #
    # @param [Symbol] name of hook to call
    # @param *args Hook arguments
    # @return [Array] [*Before hook results, Block result, *After hook results]
    # @api public
    #
    def with_hooks(name, *args)
      result = []
      result.push(*invoke_hook("BEFORE #{name}", *args))
      result << yield
    ensure
      result.push(*invoke_hook("AFTER #{name}", *args))
    end

    # Invoke hooks registered for this class
    #
    # The hooks can be registered using {ClassMethods#hook}.
    #
    # @param [Symbol] name of hook to call
    # @param *args Hook arguments
    # @return [Array] [Hook results]
    # @api public
    #
    def invoke_hook(name, *args)
      hooks = self.class.hooks[name.to_sym]
      raise "#{self.class} has no hook '#{name}'" if !hooks
      hooks.sort_by(&:first).map {|x| send(x.last, *args) }
    end

    # Extends class with hook functionality
    module ClassMethods
      # Hash of registered hooks
      # @api private
      # @return [Hash] of hooks
      def hooks
        @hooks ||= {}
      end

      def has_around_hooks(*names)
        names.each do |name|
          has_hooks "BEFORE #{name}", "AFTER #{name}"
        end
      end

      def has_hooks(*names)
        names.map(&:to_sym).each do |name|
          raise "#{self} already has hook '#{name}'" if hooks.include?(name)
          hooks[name] = []
        end
      end

      # Register hook for class
      #
      # The hook will be invoked by {#invoke_hook}. Hooks with lower priority are called first.
      #
      # @param [Symbol, String] name of hook
      # @param [Integer] priority
      # @yield Hook block with arguments matching the hook invocation
      # @return [void]
      # @api public
      #
      def hook(name, priority = 99, &block)
        list = hooks[name.to_sym]
        raise "#{self} has no hook '#{name}'" if !list
        method = "HOOK #{name} #{list.size}"
        define_method(method, &block)
        list << [priority, method]
      end

      # Register before hook
      #
      # The hook will be invoked by {#with_hooks}.
      #
      # @param [Symbol, String] name of hook
      # @param [Integer] priority
      # @yield Hook block with arguments matching the hook invocation
      # @return [void]
      # @api public
      #
      def before(name, priority = 99, &block)
        hook("BEFORE #{name}", priority, &block)
      end

      # Register before hook
      #
      # The hook will be invoked by {#with_hooks}.
      #
      # @param [Symbol, String] name of hook
      # @param [Integer] priority
      # @yield Hook block with arguments matching the hook invocation
      # @return [void]
      # @api public
      #
      def after(name, priority = 99, &block)
        hook("AFTER #{name}", priority, &block)
      end
    end
  end
end
