module Olelo
  module Middleware
    class StaticCache
      def initialize(app)
        @app = app
      end

      def call(env)
        # Add a cache-control header if asset is static with version string
        if env['PATH_INFO'].sub!(%r{^/static-\w+/}, '/static/')
          status, headers, body = @app.call(env)
          headers['Cache-Control'] = 'public, max-age=31536000'
          [status, headers, body]
        else
          @app.call(env)
        end
      end
    end
  end
end
