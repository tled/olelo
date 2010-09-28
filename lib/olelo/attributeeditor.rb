module Olelo
  # Include module to add attribute editor to a class.
  module AttributeEditor
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Attribute data structure
    # @api private
    class Attribute
      include Util

      # @api private
      attr_reader :key, :name

      def initialize(name, parent, type)
        @name = name.to_s
        @key = [parent.key, name].compact.join('_')
        @type = type
      end

      # Returns translated attribute label
      #
      # @return [String]
      # @api private
      #
      def label
        @label ||= Locale.translate("attribute_#{@key}", :fallback => titlecase(name))
      end

      # Build form for this attribute
      # @return [String] html
      # @api private
      #
      def build_form(attr)
        type = @type.respond_to?(:call) ? @type.call : @type
        title = Symbol === type ? Locale.translate("type_#{type}", :fallback => titlecase(type)) : :type_select.t
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

      # Parse params and return attribute value
      # @return [Integer, String, Array of Strings] Attribute value
      # @api private
      #
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

    # Data structure for group of attributes
    # @api private
    class AttributeGroup
      include Util

      # @api private
      attr_reader :name, :key, :children, :label

      def initialize(name, parent)
        @name = name.to_s
        @key = parent ? [parent.key, name].compact.join('_') : nil
        @children = {}
      end

      # Returns translated group label
      #
      # @return [String]
      # @api private
      #
      def label
        @label ||= name.blank? ? '' :
          Locale.translate("group_#{@key}", :fallback => [@parent ? @parent.label : nil, titlecase(name)].compact.join(' '))
      end

      # Build form for this group
      # @return [String] html
      # @api private
      #
      def build_form(attr)
        html = label.blank? ? '' : "<h3>#{escape_html label}</h3>\n"
        html << children.sort_by {|name, child| [Attribute === child ? 0 : 1, child.label] }.
          map { |name, child| child.build_form(attr ? attr[name] : nil) }.join
      end

      # Parse params and return attribute hash for this group
      # @return [Hash]
      # @api private
      #
      def parse(params)
        attr = {}
        children.each do |name, child|
          value = child.parse(params)
          attr[name] = value if value
        end
        attr.empty? ? nil : attr
      end
    end

    # DSL class used to initialize AttributeGroup
    class AttributeDSL
      include Util

      # Initialize DSL with `group`
      #
      # @param [Olelo::AttributeEditor::AttributeGroup] AttributeGroup to modify in this DSL block
      # @yield DSL block
      #
      def initialize(group, &block)
        @group = group
        instance_eval(&block)
      end

      # Define attribute
      #
      # Type can be `:boolean`, `:integer`, `:string`, `:stringlist`
      # or an `Array` or a `Hash`. Arrays and Hashes generate a selection field.
      #
      # @param [Symbol, String] name of attribute
      # @param [:boolean, :integer, :string, :stringlist, Array, Hash] type of attribute
      # @yield Block which must return type
      # @return [void]
      # @api public
      #
      def attribute(name, type = nil, &block)
        @group.children[name.to_s] = Attribute.new(name, @group, block ? block : type)
      end

      # Define attribute group
      #
      # @yield DSL block
      # @return [void]
      # @api public
      #
      def group(name, &block)
        AttributeDSL.new(@group.children[name.to_s] ||= AttributeGroup.new(name, @group), &block)
      end
    end

    # Extends class with attribute editor DSL
    module ClassMethods
      # Root attribute editor group
      #
      # @return [AttributeGroup] Root editor group
      # @api private
      #
      def attribute_editor_group
        @attribute_editor_group ||= AttributeGroup.new(nil, nil)
      end

      # Add attribute to the attribute editor
      #
      # @yield DSL block
      # @return [void]
      # @api public
      #
      # @example add string attribute title
      #   attribute_editor do
      #     attribute :title, :string
      #   end
      #
      # @example add group with multiple attributes
      #   attribute_editor do
      #     group :acl do
      #       attribute :read, :stringlist
      #       attribute :write, :stringlist
      #     end
      #
      def attribute_editor(&block)
        AttributeDSL.new(attribute_editor_group, &block)
      end
    end

    # Parse attributes from params hash
    #
    # @param [Hash] params submitted params hash
    # @return [Hash] Attributes
    # @api public
    #
    def parse_attributes(params)
      self.class.attribute_editor_group.parse(params)
    end

    # Generate attribute editor form
    #
    # @param [Hash] default_values to use for the form
    # @return [String] Generated html form
    # @api public
    #
    def attribute_editor(default_values)
      self.class.attribute_editor_group.build_form(default_values)
    end
  end
end
