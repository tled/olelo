module Olelo
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
    def invoke_hook(type, *args)
      self.class.hooks[type].to_a.sort_by(&:first).map {|priority, name| send(name, *args) }
    end

    # Invoke exception hooks registered for this class
    #
    # The exception handlers were registered by {ClassMethods#hook}.
    #
    # @param [Exception] exception to handle
    # @return [Array] [Handler results]
    # @api public
    #
    def invoke_exception_hook(exception)
      result = []
      type = exception.class
      while type
        result.push(*invoke_hook(type, exception))
        break if type == Exception
        type = type.superclass
      end
      result
    end

    # Extends class with hook functionality
    module ClassMethods
      # Hash of registered hooks
      # @api private
      # @return [Hash] of hooks
      def hooks
        @hooks ||= {}
      end

      # Register hook for class
      #
      # The hook will be invoked by {#invoke_hook}. Hooks with lower priority are called first.
      #
      # @param [Symbol] name of hook
      # @param [Integer] priority
      # @yield Hook block with arguments matching the hook invocation
      # @return [void]
      # @api public
      #
      def hook(name, priority = 99, &block)
        hooks[name] ||= []
        method = "HOOK #{name} #{hooks[name].size}"
        define_method(method, &block)
        hooks[name] << [priority, method]
      end

      # Register before hook
      #
      # The hook will be invoked by {#with_hooks}.
      #
      # @param [Symbol] name of hook
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
      # @param [Symbol] name of hook
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
