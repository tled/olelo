module Olelo
  module Middleware
    class DegradeMimeType
      def initialize(app)
        @app = app
      end

      def call(env)
        status, header, body = @app.call(env)
        if header['Content-Type'] =~ %r{application/xhtml\+xml} &&
            !env['HTTP_ACCEPT'].to_s.split(',').map(&:strip).include?('application/xhtml+xml')
          header['Content-Type'] = 'text/html'
        end
        [status, header, body]
      end
    end
  end
end
