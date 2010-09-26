module Olelo
  module AttributeEditor
    def self.included(base)
      base.extend(ClassMethods)
    end

    class Attribute
      include Util

      attr_reader :key, :name

      def initialize(name, parent, type)
        @name = name.to_s
        @key = [parent.key, name].compact.join('_')
        @type = type
      end

      def label
        @label ||= I18n.translate("attribute_#{@key}", :fallback => capitalize_words(name))
      end

      def build_form(attr)
        type = @type.respond_to?(:call) ? @type.call : @type
        title = Symbol === type ? I18n.translate("type_#{type}", :fallback => capitalize_words(type)) : :type_select.t
        html = %{<label for="attribute_#{key}" title="#{escape_html title}">#{label}</label>}
	case type
        when :integer, :string
          html << %{<input class="confirm" type="text" id="attribute_#{key}" name="attribute_#{key}" value="#{escape_html attr}"/>}
        when :stringlist
          html << %{<input class="confirm" type="text" id="attribute_#{key}" name="attribute_#{key}" value="#{escape_html attr.to_a.join(', ')}"/>}
        when :boolean
          html << %{<input class="confirm" type="checkbox" id="attribute_#{key}" name="attribute_#{key}" value="true"#{attr ? ' checked="checked"' : ''}/>}
        when Hash
          html << %{<select class="confirm" id="attribute_#{key}" name="attribute_#{key}">
                    <option#{type.any? {|value,label| attr == value} ? '' : ' selected="selected"'}></option>}
          type.sort_by(&:last).each do |value,label|
            html << %{<option value="#{escape_html value}"#{attr == value ? ' selected="selected"' : ''}>#{escape_html label}</option>}
          end
          html << '</select>'
        when Array
          html << %{<select class="confirm" id="attribute_#{key}" name="attribute_#{key}">
                    <option#{type.any? {|value| attr == value} ? '' : ' selected="selected"'}></option>}
          type.sort.each do |value|
            html << %{<option#{attr == value ? ' selected="selected"' : ''}>#{escape_html value}</option>}
          end
          html << '</select>'
        else
          raise "Invalid attribute type #{type}"
        end
        html + "<br/>\n"
      end

      def parse(params)
        value = params["attribute_#{key}"]
        type = @type.respond_to?(:call) ? @type.call : @type
        case type
        when :integer
          value.to_i if !value.blank?
        when :boolean
          true if value == 'true'
        when :string
          value if !value.blank?
        when :stringlist
          value.split(/\s*,\s*/) if !value.blank?
        when Array, Hash
          value if type.include?(value)
        else
          raise "Invalid attribute type #{type}"
        end
      end
    end

    class AttributeGroup
      include Util

      attr_reader :name, :key, :children, :label

      def initialize(name, parent)
        @name = name.to_s
        @key = parent ? [parent.key, name].compact.join('_') : nil
        @children = {}
      end

      def label
        @label ||= name.blank? ? '' : I18n.translate("group_#{@key}",
                                                     :fallback => [@parent ? @parent.label : nil, capitalize_words(name)].compact.join(' '))
      end

      def build_form(attr)
        html = label.blank? ? '' : "<h3>#{escape_html label}</h3>\n"
        html << children.sort_by {|name, child| [Attribute === child ? 0 : 1, child.label] }.
          map { |name, child| child.build_form(attr ? attr[name] : nil) }.join
      end

      def parse(params)
        attr = {}
        children.each do |name, child|
          value = child.parse(params)
          attr[name] = value if value
        end
        attr.empty? ? nil : attr
      end

      class DSL
        include Util

        def initialize(group, &block)
          @group = group
          instance_eval(&block)
        end

        def attribute(name, type = nil, &block)
          @group.children[name.to_s] = Attribute.new(name, @group, block ? block : type)
        end

        def group(name, &block)
          DSL.new(@group.children[name.to_s] ||= AttributeGroup.new(name, @group), &block)
        end
      end
    end

    module ClassMethods
      def attribute_editor_group
        @attribute_editor_group ||= AttributeGroup.new(nil, nil)
      end

      def attribute_editor(&block)
        AttributeGroup::DSL.new(attribute_editor_group, &block)
      end
    end

    def parse_attributes
      self.class.attribute_editor_group.parse(params)
    end

    def attribute_editor
      self.class.attribute_editor_group.build_form(page.attributes)
    end
  end
end
