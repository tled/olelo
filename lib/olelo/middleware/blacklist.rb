module Olelo
  module Middleware
    class Blacklist
      def initialize(app, options)
        @app = app
        @list = options[:blacklist]
      end

      def call(env)
        if %w(POST PUT DELETE).include?(env['REQUEST_METHOD']) && @list.include?(Rack::Request.new(env).ip)
          env.delete('rack.request.form_vars')
          env.delete('rack.request.form_hash')
          env.delete('rack.request.form_input')
          env['rack.input'] = ::File.open('/dev/null', 'rb')
          env['REQUEST_METHOD'] = 'GET'
        end
        @app.call(env)
      end
    end
  end
end
