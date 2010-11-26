description  'Extends wiki text with custom xml tags'
dependencies 'aspect/filter'

# Simple XML tag parser based on regular expressions
class TagSoupParser
  include Util

  NAME            = /[\-\w]+(?:\:[\-\w]+)?/
  QUOTED_VALUE    = /"[^"]*"|'[^']*'/
  UNQUOTED_VALUE  = /(?:[^\s'"\/>]|\/+[^'"\/>])+/
  QUOTED_ATTR     = /(#{NAME})=(#{QUOTED_VALUE})/
  UNQUOTED_ATTR   = /(#{NAME})=(#{UNQUOTED_VALUE})/
  BOOL_ATTR       = /(#{NAME})/
  ATTRIBUTE       = /\A\s*(#{QUOTED_ATTR}|#{UNQUOTED_ATTR}|#{BOOL_ATTR})/

  # enabled_tags must be a hash of tag names
  # that will be recognized by the parser.
  # Hash values must be true for autoclosing tags and false otherwise.
  # Other tags are ignored.
  def initialize(enabled_tags, content)
    @enabled_tags, @content = enabled_tags, content
    @output = ''
    @parsed = nil
  end

  # Parse the content and call the block
  # for every recognized tag.
  # The block gets two arguments,
  # the attribute hash and the content of the tag.
  # Another instance of the parser has to parse the content to support nested tags.
  def parse(&block)
    while @content =~ /<(#{NAME})/
      @output << $`
      @content = $'
      name = $1.downcase
      if @enabled_tags.include?(name)
        @name = name
        @parsed = $&
        parse_tag(&block)
      else
        # unknown tag, continue parsing after it
        @output << $&
      end
    end
    @output << @content
  end

  private

  # Parse the attribute list
  # Allowed attribute formats
  #   name="value"
  #   name='value'
  #   name=value (no space, ' or " allowed in value)
  #   name (for boolean values)
  def parse_attributes
    @attrs = Hash.with_indifferent_access
    while @content =~ ATTRIBUTE
      @content = $'
      @parsed << $&
      match = $&
      case match
      when QUOTED_ATTR
        @attrs[$1] = unescape_html($2[1...-1])
      when UNQUOTED_ATTR
        @attrs[$1] = unescape_html($2)
      when BOOL_ATTR
        @attrs[$1] = $1
      end
    end
  end

  # Parse a tag after the beginning "<@name"
  def parse_tag
    parse_attributes

    case @content
    when /\A\s*(\/?)>/
      @content = $'
      @parsed << $&
      @output << yield(@name, @attrs, !$1.blank? || @enabled_tags[@name] ? '' : get_content)
    else
      # Tag which begins with <name but has no >.
      # Ignore this and continue parsing after it.
      @output << @parsed
    end
  end

  # Collect the inner content of the tag
  def get_content
    stack = [@name]
    text = ''
    while !stack.empty?
      case @content
      # Tag begins
      when /\A<(#{NAME})/
        @content = $'
        text << $&
        stack << $1
      # Tag ends
      when /\A<\/(#{NAME})>/
        @content = $'
        if i = stack.rindex($1.downcase)
          stack = stack[0...i]
          text << $& if !stack.empty?
        else
          text << $&
        end
      # Text till the next tag beginning
      when /\A[^<]+/
        text << $&
        @content = $'
      # Suprious <
      when /\A</
        text << '<'
        @content = $'
      # No closing tag
      else
        @content.clear
        text << @content
        break
      end
    end
    text
  end
end

class Olelo::Tag < AroundFilter
  @@tags = {}

  def self.tags
    @@tags
  end

  # Define a tag which is executed by the tag filter
  #
  # Supported options:
  #   * :limit       - Limit tag count
  #   * :optional    - List of optional attributes (* to allow arbitrary)
  #   * :requires    - List of required attributes
  #   * :dynamic     - Dynamic tags are uncached, the content is generated
  #                    on the fly everytime the page is rendered.
  #                    Warning: Dynamic tags introduce a large overhead!
  #   * :immediate   - Replace tag immediately with generated content.
  #                    This means BEFORE the execution of the subfilter.
  #                    Immediate tags can generate wiki text which is then parsed by the subfilter.
  #                    The default behaviour is that tags are not immediate.
  #                    The content is not parsed by the subfilter, this is useful for html generation.
  #   * :description - Tag description, by default the plugin description
  #   * :namespace   - Namespace of the tag, by default the plugin name
  #
  # Tags are added as methods to this filter. This means every method
  # of this class can be called from the tag block.
  # Dynamic tags are an exception. They are executed later from the layout hook.
  def self.define(name, options = {}, &block)
    raise 'Dynamic tag cannot be immediate' if options[:dynamic] && options[:immediate]
    raise 'Tag must take two or three arguments' if block.arity != 2 && block.arity != 3
    # Find the plugin which provided this tag.
    plugin = Plugin.current(1) || Plugin.current
    options.merge!(:name => name.to_s, :plugin => plugin, :autoclose => block.arity == 2,
                   :optional => Set.new([*options[:optional]].compact.flatten.map(&:to_s)),
                   :requires => Set.new([*options[:requires]].compact.flatten.map(&:to_s)))
    options[:description] ||= plugin.description
    options[:namespace] ||= plugin.name.split('/').last
    tag = TagInfo.new(options)
    @@tags[tag.full_name] = @@tags[tag.name] = tag
    if tag.dynamic
      klass = Class.new
      klass.class_eval do
        include PageHelper
        include Templates
        define_method(:call, &block)
      end
      tag.dynamic = klass
    else
      define_method("TAG #{tag.full_name}", &block)
    end
  end

  # Configure the tag filter
  # Options:
  #   * :enable  - Whitelist of tags to enable
  #   * :disable - Blacklist of tags to disable
  #   * :static  - Execute dynamic tags only once
  #
  # Examples:
  #   :enable => %w(html:* include) Enables all tags in the html namespace and the include tag.
  def configure(options)
    super
    list = @options[:enable] ? tag_list(*@options[:enable]) : @@tags.keys
    list -= tag_list(*@options[:disable]) if @options[:disable]
    @enabled_tags = list.inject({}) do |hash, name|
      hash[name] = @@tags[name].autoclose
      hash
    end
    @static = options[:static]
  end

  # Parse nested tags. This method can be called from tag blocks.
  def nested_tags(context, content)
    context.private[:tag_level] ||= 0
    context.private[:tag_level] += 1
    return 'Maximum tag nesting exceeded' if context.private[:tag_level] > MAX_RECURSION
    result = TagSoupParser.new(@enabled_tags, content).parse do |name, attrs, text|
      process_tag(name, attrs, text, context)
    end
    context.private[:tag_level] -= 1
    result
  end

  # Execute the subfilter on content. Tags are also evaluated.
  def subfilter(context, content)
    super(context, nested_tags(context, content))
  end

  # Main filter method
  def filter(context, content)
    @protected_tags = []
    @protection_prefix = "TAG#{object_id}X"
    @protection_suffix = 'X'
    replace_protected_tags(subfilter(context, content))
  end

  private

  def tag_list(*list)
    @@tags.select do |name, tag|
      list.include?(tag.name) ||
      list.include?(tag.full_name) ||
      list.include?("#{tag.namespace}:*")
    end.map(&:last)
  end

  MAX_RECURSION = 100
  BLOCK_ELEMENTS = %w(style script address blockquote div h1 h2 h3 h4 h5 h6 ul p ol pre table hr br)
  BLOCK_ELEMENT_REGEX = /<(#{BLOCK_ELEMENTS.join('|')})/

  class TagInfo
    attr_accessor :name, :namespace, :limit, :optional, :requires,
                  :autoclose, :immediate, :dynamic, :description, :plugin

    def full_name
      "#{namespace}:#{name}"
    end

    def initialize(options)
      options.each_pair {|k,v| send("#{k}=", v) }
    end
  end

  def process_tag(name, attrs, content, context)
    tag = @@tags[name]
    name = tag.full_name

    tag_counter = context.private[:tag_counter] ||= {}
    tag_counter[name] ||= 0
    tag_counter[name] += 1

    raise 'Tag limit exceeded' if tag.limit && tag_counter[name] > tag.limit

    required = tag.requires.find {|a| !attrs.include?(a) }
    raise %{Attribute "#{required}" is required} if required

    if !tag.optional.include?('*')
      invalid = attrs.keys.find {|a| !tag.requires.include?(a) && !tag.optional.include?(a) }
      raise %{Attribute "#{invalid}" is invalid} if invalid
    end

    args = [context, attrs, content]
    args.pop if tag.autoclose

    content =
      if tag.dynamic
        if @static
          tag.dynamic.new.call(*args).to_s
        else
          args[0] = name
          %{DYNTAG(#{encode64 Marshal.dump(args)})}
        end
      else
        send("TAG #{name}", *args).to_s
      end

    if tag.immediate
      content
    else
      @protected_tags << content
      "#{@protection_prefix}#{@protected_tags.length-1}#{@protection_suffix}"
    end
  rescue Exception => ex
    Plugin.current.logger.error ex
    "#{name} - #{ex.message}"
  end

  def replace_protected_tags(content)
    # Protected elements can be nested into each other
    MAX_RECURSION.times do
      break if !content.gsub!(/#{@protection_prefix}(\d+)#{@protection_suffix}/) do
        element = @protected_tags[$1.to_i]

        # Remove unwanted <p>-tags around block-level-elements
        prefix = $`
        if element =~ BLOCK_ELEMENT_REGEX
          count = prefix.scan('<p>').size - prefix.scan('</p>').size
          count > 0 ? '</p>' + element + '<p>' : element
        else
          element
        end
      end
      content.gsub!(%r{<p>\s*</p>}, '')
    end
    content
  end
end

# Evaluate and replace all dynamic tags on the page
Application.hook :render, 2000 do |name, xml, layout|
  no_cache = false
  xml.gsub!(/DYNTAG\(([^\)]+)\)/) do
    no_cache = true
    begin
      name, attrs, content = Marshal.load(decode64($1))
      raise 'Invalid dynamic tag' unless Hash === attrs && Tag.tags[name] && Tag.tags[name].dynamic
      begin
        context = Context.new(:page => page, :params => params, :request => request, :response => response)
        if content
          raise 'Invalid dynamic tag' unless String === content
          Tag.tags[name].dynamic.new.call(context, attrs, content).to_s
        else
          Tag.tags[name].dynamic.new.call(context, attrs).to_s
        end
      rescue Exception => ex
        Plugin.current.logger.error ex
        "#{name} - #{escape_html ex.message}"
      end
    rescue Exception => ex
      Plugin.current.logger.error ex
      ''
    end
  end
  cache_control(:no_cache => true) if no_cache
end

Filter.register :tag, Tag, :description => 'Process extension tags'

Tag.define :nowiki, :description => 'Disable tag and wikitext filtering' do |context, attrs, content|
  escape_html(content)
end

Tag.define :notags, :description => 'Disable tag processing', :immediate => true do |context, attrs, content|
  content
end

# Dynamic test tag
Tag.define :fortune, :autoclose => true, :description => 'Show fortune message', :dynamic => true do |context, attrs|
  text = `fortune`
  escape_html(text) if valid_xml_chars?(text)
end
