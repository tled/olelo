module Olelo
  module Middleware
    class StaticCache
      def initialize(app)
        @app = app
      end

      def call(env)
        # Add a cache-control header if asset is static and version is appended as query string
        if env['PATH_INFO'] =~ %r{^/static} && !env['QUERY_STRING'].blank?
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
