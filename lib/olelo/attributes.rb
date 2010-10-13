module Olelo
  # Include module to add attribute editor to a class.
  module Attributes
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Attribute data structure
    # @api private
    class Attribute
      include Util

      # @api private
      attr_reader :key, :name

      def initialize(parent, name)
        @name = name.to_s
        @key = ['attribute', parent.path, name].compact.join('_')
      end

      def label
        @label ||= Locale.translate(key, :fallback => titlecase(name))
      end

      def label_tag
        type = self.class.name.split('::').last.downcase
        title = Locale.translate("type_#{type}", :fallback => titlecase(type))
        %{<label for="#{key}" title="#{escape_html title}">#{escape_html label}</label>}
      end

      def build_form(attr)
        "#{label_tag}#{field_tag(attr)}<br/>"
      end

      class String < Attribute
        def field_tag(attr)
          %{<input class="observe" type="text" id="#{key}" name="#{key}" value="#{escape_html attr}"/>}
        end

        def parse(params)
          value = params[key]
          value if !value.blank?
        end
      end

      class List < Attribute
        def field_tag(attr)
          %{<input class="observe" type="text" id="#{key}" name="#{key}" value="#{escape_html attr.to_a.join(', ')}"/>}
        end

        def parse(params)
          value = params[key]
          value.split(/\s*,\s*/) if !value.blank?
        end
      end

      class Integer < Attribute
        def field_tag(attr)
          %{<input class="observe" type="text" id="#{key}" name="#{key}" value="#{escape_html attr}"/>}
        end

        def parse(params)
          value = params[key]
          value.to_i if !value.blank?
        end
      end

      class Boolean < Attribute
        def field_tag(attr)
          %{<input class="observe" type="checkbox" id="#{key}" name="#{key}" value="true"#{attr ? ' checked="checked"' : ''}/>}
        end

        def build_form(attr)
          "<div class=\"indent\">#{field_tag(attr)}#{label_tag}</div><br/>\n"
        end

        def parse(params)
          value = params[key]
          true if value == 'true'
        end
      end

      class Enum < Attribute
        def initialize(parent, name, values = {})
          super(parent, name)
          raise 'Values must be Proc, Hash or Array' unless Proc === values || Hash === values || Array === values
          @values = values
        end

        def field_tag(attr)
          html = %{<select class="observe" id="#{key}" name="#{key}">
                   <option#{values.any? {|value,label| attr == value} ? '' : ' selected="selected"'}></option>}
          values.sort_by(&:last).each do |value,label|
            value_attr = value == label ? '' : %{ value="#{escape_html value}"}
            selected_attr = attr == value ? ' selected="selected"' : ''
            html << %{<option#{value_attr}#{selected_attr}>#{escape_html label}</option>}
          end
          html << '</select>'
        end

        def parse(params)
          value = params[key]
          value if values.include?(value)
        end

        private

        def values
          if Proc === @values
            @values = @values.call
            raise 'Values must be Hash or Array' unless Hash === @values || Array === @values
          end
          @values = Hash[*@values.zip(@values)] if Array === @values
          @values
        end
      end

      class Suggestions < Enum
        def field_tag(attr)
          %{<input class="observe" type="text" id="#{key}" name="#{key}" value="#{escape_html(values[attr] || attr)}"/>
            <script type="text/javascript">
            $('##{key}').combobox({ source: #{escape_javascript values.values.sort.to_json} });
            </script>}
        end

        def parse(params)
          value = params[key]
          inverted_values[value] || value if !value.blank?
        end

        def inverted_values
          @inverted_values ||= values.invert
        end
      end
    end

    # Data structure for group of attributes
    # @api private
    class AttributeGroup
      include Util

      # @api private
      attr_reader :name, :path, :children

      def initialize(parent = nil, name = nil)
        @name = name.to_s
        @path = parent ? [parent.path, name].compact.join('_') : nil
        @children = {}
      end

      def label
        @label ||= name.blank? ? '' : Locale.translate("group_#{path}", :fallback => titlecase(name))
      end

      # Build form for this group
      # @return [String] html
      # @api private
      #
      def build_form(attr)
        html = label.blank? ? '' : "<h3>#{escape_html label}</h3>\n"
        html << children.sort_by do |name, child|
          [Attribute === child ? 0 : 1, child.label]
        end.map do |name, child|
          child.build_form(attr ? attr[name] : nil)
        end.join
      end

      # Parse params and return attribute hash for this group
      # @return [Hash]
      # @api private
      #
      def parse(params)
        attr = {}
        children.each_pair do |name, child|
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
      # @param [Olelo::Attributes::AttributeGroup] AttributeGroup to modify in this DSL block
      # @yield DSL block
      #
      def initialize(group, &block)
        @group = group
        instance_eval(&block)
      end

      def string(name, values = nil, &block)
        @group.children[name.to_s] = if values || block
                                       Attribute::Suggestions.new(@group, name, block ? block : values)
                                     else
                                       Attribute::String.new(@group, name)
                                     end
      end

      def integer(name)
        @group.children[name.to_s] = Attribute::Integer.new(@group, name)
      end

      def boolean(name)
        @group.children[name.to_s] = Attribute::Boolean.new(@group, name)
      end

      def list(name)
        @group.children[name.to_s] = Attribute::List.new(@group, name)
      end

      def enum(name, values = nil, &block)
        @group.children[name.to_s] = Attribute::Enum.new(@group, name, block ? block : values)
      end

      # Define attribute group
      #
      # @yield DSL block
      # @return [void]
      # @api public
      #
      def group(name, &block)
        AttributeDSL.new(@group.children[name.to_s] ||= AttributeGroup.new(@group, name), &block)
      end
    end

    # Extends class with attribute editor DSL
    module ClassMethods
      # Root attribute group
      #
      # @return [AttributeGroup] Root editor group
      # @api private
      #
      def attribute_group
        @attribute_group ||= AttributeGroup.new
      end

      # Add attribute to the attribute editor
      #
      # @yield DSL block
      # @return [void]
      # @api public
      #
      # @example add string attribute title
      #   attributes do
      #     string :title
      #   end
      #
      # @example add group with multiple attributes
      #   attributes do
      #     group :acl do
      #       list :read
      #       list :write
      #     end
      #
      def attributes(&block)
        AttributeDSL.new(attribute_group, &block)
      end
    end

    # Parse attributes from params hash
    #
    # @param [Hash] params submitted params hash
    # @return [Hash] Attributes
    # @api public
    #
    def update_attributes(params)
      self.attributes = self.class.attribute_group.parse(params)
    end

    # Generate attribute editor form
    #
    # @param [Hash] default_values to use for the form
    # @return [String] Generated html form
    # @api public
    #
    def attribute_editor
      self.class.attribute_group.build_form(attributes)
    end
  end
end
