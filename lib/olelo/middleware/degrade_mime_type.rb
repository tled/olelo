module Olelo
  module Middleware
    class DegradeMimeType
      def initialize(app)
        @app = app
      end

      def call(env)
        status, header, body = @app.call(env)
        if env['HTTP_ACCEPT'].to_s !~ %r{application/xhtml\+xml}
          if header['Content-Type'] =~ %r{\Aapplication/xhtml\+xml(;?.*)\Z}
            header['Content-Type'] = "text/html#{$1}"
          end
        end
        [status, header, body]
      end
    end
  end
end
