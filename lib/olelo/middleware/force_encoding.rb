module Olelo
  module Middleware
    class ForceEncoding
      def initialize(app, encoding = Encoding.default_external)
        @app, @encoding = app, encoding
      end

      def call(env)
        request = Rack::Request.new(env)
        encode(env)
        encode(request.params)
        @app.call(env)
      end

      private

      def encode(x)
        case x
        when Hash
          y = x.frozen? ? {} : x
          x.each { |k,v| y[k] = encode(v) }
          y
        when Array
          y = x.frozen? ? [] : x
          x.each_with_index {|v,i| y[i] = encode(v) }
          y
        when String
          # Try to force encoding and revert to old encoding if this doesn't work
          if x.encoding != @encoding
            x = x.dup if x.frozen?
            x.try_encoding(@encoding)
          else
          x
          end
        else
          x
        end
      end
    end
  end
end
