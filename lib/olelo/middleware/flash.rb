module Olelo
  module Middleware
    class Flash
      # Implements bracket accessors for storing and retrieving flash entries.
      class FlashHash
        def initialize(session, opts = {})
          @session = session
          raise 'No session available' if !session
          [*opts[:accessors]].compact.each {|a| def_accessor(a) }
          [*opts[:array_accessors]].compact.each {|a| def_array_accessor(a) }
        end

        # Remove an entry from the session and return its value. Cache result in
        # the instance cache.
        def [](key)
          key = key.to_sym
          cache[key] ||= values.delete(key)
        end

        # Store the entry in the session, updating the instance cache as well.
        def []=(key,val)
          key = key.to_sym
          cache[key] = values[key] = val
        end

        # Store a flash entry for only the current request, swept regardless of
        # whether or not it was actually accessed. Useful for AJAX requests, where
        # you want a flash message, even though you're response isn't redirecting.
        def now
          cache
        end

        # Checks for the presence of a flash entry without retrieving or removing
        # it from the cache or store.
        def include?(key)
          key = key.to_sym
          cache.keys.include?(key) || values.keys.include?(key)
        end

        # Clear the hash
        def clear
          cache.clear
          @session.delete(:olelo_flash)
        end

        # Mark existing entries to allow for sweeping.
        def flag!
          @flagged = values.keys
        end

        # Remove flagged entries from flash session, clear flagged list.
        def sweep!
          @flagged.to_a.each {|key| values.delete(key) }
          @flagged = nil
        end

        # Hide the underlying olelo.flash session key and only expose values stored
        # in the flash.
        def inspect
          "#<FlashHash @values=#{values.inspect} @cache=#{cache.inspect}>"
        end

        # Human readable for logging.
        def to_s
          values.inspect
        end


        private

        # Maintain an instance-level cache of retrieved flash entries. These
        # entries will have been removed from the session, but are still available
        # through the cache.
        def cache
          @cache ||= {}
        end

        # Helper to access flash entries from olelo.flash session value. This key
        # is used to prevent collisions with other user-defined session values.
        def values
          @session[:olelo_flash] ||= {}
        end

        # Generate accessor methods for the given entry key
        def def_accessor(key)
          key = key.to_sym
          raise ArgumentError.new('Invalid entry type: %s' % key) if respond_to?(key)
          metaclass.class_eval do
            define_method(key) {|*a| a.size > 0 ? (self[key] = a[0]) : self[key] }
            define_method("#{key}=") {|val| self[key] = val }
            define_method("#{key}!") {|val| cache[key] = val }
          end
        end

        # Generate array accessor method for the given entry key
        def def_array_accessor(key)
          key = key.to_sym
          raise ArgumentError.new('Invalid entry type: %s' % key) if respond_to?(key)
          metaclass.class_eval do
            define_method(key) {|*val| val.size > 0 ? (self[key] ||= []).push(*val) : self[key] }
          end
        end
      end

      def initialize(app, opts = {})
        @app, @opts = app, opts
      end

      def call(env)
        session = env['rack.session']
        env['olelo.flash'] ||= FlashHash.new(session, @opts)
        env['olelo.flash'].flag! if @opts[:sweep]
        result = @app.call(env)
        env['olelo.flash'].sweep! if @opts[:sweep]
        session.delete(:olelo_flash) if session[:olelo_flash].blank?
        result
      end
    end
  end
end
