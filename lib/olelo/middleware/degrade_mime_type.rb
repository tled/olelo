module Olelo
  module Middleware
    class DegradeMimeType
      def initialize(app)
        @app = app
      end

      def call(env)
        status, header, body = @app.call(env)
        if header['Content-Type'] && header['Content-Type'] =~ %r{\Aapplication/xhtml\+xml(;?.*)\Z}
          charset = $1
          if env['HTTP_ACCEPT'].to_s !~ %r{application/xhtml\+xml}
            header['Content-Type'] = "text/html#{charset}"
          end
        end
        [status, header, body]
      end
    end
  end
end
