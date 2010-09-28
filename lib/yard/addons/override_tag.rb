module YARD::Tags
  class OverrideTag < Tag
    def initialize(tag_name, text)
      super(tag_name, text)
    end

    def text
      "{#{object.namespace.superclass}##{object.name(false)}}"
    end
  end

  Library.define_tag "Override", :override, OverrideTag
  Library.visible_tags.place(:override).before(:return)
end
