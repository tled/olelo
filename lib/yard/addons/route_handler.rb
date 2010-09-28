module YARD
  module Handlers
    class RouteHandler < Ruby::Base
      handles method_call(:get)
      handles method_call(:post)
      handles method_call(:put)
      handles method_call(:delete)
      handles method_call(:head)

      def register_route(name, explicit)
        register CodeObjects::MethodObject.new(namespace, name, :instance) do |o|
          o.visibility = "public"
          o.source = statement.source
          o.signature = name
          o.explicit = explicit
          o.scope = scope
          o.docstring = statement.comments
          o.sanitize_anchor = true
          o.add_file(parser.file, statement.line)
        end
      end

      def process
        path = statement.parameters.first.source
        if path =~ /'(.*)'/
          verb = statement.method_name(true).to_s.upcase
          register_route("HEAD #{$1}", false) if verb == 'GET'
          register_route("#{verb} #{$1}", true)
        end
      end
    end
  end
end
