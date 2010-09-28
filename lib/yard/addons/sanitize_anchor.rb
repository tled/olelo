module YARD
  class CodeObjects::Base
    attr_accessor :sanitize_anchor
  end

  module Templates::Helpers::HtmlHelper
    alias anchor_for_without_sanitize anchor_for
    def anchor_for(object)
      if CodeObjects::Base === object && object.sanitize_anchor
        anchor_for_without_sanitize(object).gsub(/[^\w_\-]/, '_')
      else
        anchor_for_without_sanitize(object)
      end
    end
  end
end
