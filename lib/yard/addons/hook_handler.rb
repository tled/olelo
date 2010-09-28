module YARD
  module Handlers
    class HookHandler < Ruby::Base
      handles method_call(:hook)
      handles method_call(:before)
      handles method_call(:after)

      def process
	hook = statement.parameters.first.source
	return if hook =~ /^"(BEFORE|AFTER)/
	name = "#{statement.method_name(true).to_s.upcase} #{hook}"
        route = register CodeObjects::MethodObject.new(namespace, name, :instance) do |o|
          o.visibility = "public"
          o.source = statement.source
          o.signature = name
          o.explicit = true
          o.scope = scope
          o.docstring = statement.comments
          o.sanitize_anchor = true
          o.add_file(parser.file, statement.line)
        end
      end
    end
  end
end
