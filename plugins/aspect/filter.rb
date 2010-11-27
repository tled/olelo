description 'Filter pipeline aspect'
dependencies 'aspect/aspect'

class Olelo::MandatoryFilterNotFound < NameError; end

# Filter base class. Multiple filters can be chained
# to build a filter aspect.
# A filter can manipulate the text and the aspect context.
class Olelo::Filter
  include PageHelper
  include Templates
  extend Factory

  attr_accessor :previous
  attr_reader :name, :description, :plugin, :options

  # Initialize filter
  def initialize(name, options)
    @name        = name.to_s
    @plugin      = options[:plugin] || Plugin.current(1) || Plugin.current
    @description = options[:description] || @plugin.description
  end

  # Configure the filter. Takes an option hash
  def configure(options)
    @options = options
  end

  # Main entry point of a filter
  # Calls previous filter, creates a duplicate from itself
  # and calls filter on it.
  def call(context, content)
    content = previous ? previous.call(context, content) : content
    dup.filter(context, content)
  end

  # Filter the content. Implement this method!
  def filter(context, content)
    raise NotImplementedError
  end

  # Print filter definition. For debugging purposes.
  def definition
    previous ? "#{previous.definition} > #{name}" : name
  end

  # Register a filter class
  def self.register(name, klass, options = {})
    super(name, klass.new(name, options))
  end

  # Create a filter from a given block.
  def self.create(name, options = {}, &block)
    klass = Class.new(self)
    klass.class_eval { define_method(:filter, &block) }
    register(name, klass, options)
  end
end

# Filter which supports subfilters
class Olelo::NestingFilter < Olelo::Filter
  attr_accessor :sub

  def subfilter(context, content)
    sub ? sub.call(context, content) : content
  end

  def definition
    sub ? "#{super} (#{sub.definition})" : super
  end
end

class Olelo::FilterAspect < Aspect
  def initialize(name, options, filter)
    super(name, options)
    @filter = filter
  end

  def call(context, page)
    @filter.call(context, page.content.dup)
  end

  def definition
    @filter.definition
  end
end

# Filter DSL
class FilterDSL
  # Build filter class
  class FilterBuilder
    def initialize(name, filter = nil)
      @name, @filter = name, filter
    end

    # Add optional filter
    def filter(name, options = nil, &block)
      add(name, false, options, &block)
    end

    # Add mandatory filter
    def filter!(name, options = nil, &block)
      add(name, true, options, &block)
    end

    # Add filter with method name.
    # Mandatory filters must end with !
    def method_missing(name, options = nil, &block)
      name = name.to_s
      name.ends_with?('!') ? filter!(name[0..-2], options, &block) : filter(name, options, &block)
    end

    def build(&block)
      instance_eval(&block)
      @filter
    end

    private

    def add(name, mandatory, options = nil, &block)
      filter = Filter[name] rescue nil
      if filter
        filter = filter.dup
        filter.configure((options || {}).with_indifferent_access)
        filter.previous = @filter
        @filter = filter
        if block
          raise "Filter '#{name}' does not support subfilters" if !(NestingFilter === @filter)
          @filter.sub = FilterBuilder.new(@name).build(&block)
        end
      else
        if mandatory
          raise MandatoryFilterNotFound, "Aspect '#{@name}' not created because mandatory filter '#{name}' is not available"
        else
          Olelo.logger.warn "Optional filter '#{name}' not available"
        end
        @filter = FilterBuilder.new(@name, @filter).build(&block) if block
      end
      self
    end
  end

  # Build aspect class
  class AspectBuilder
    def initialize(name)
      @name = name
      @options = {}
    end

    def build(&block)
      instance_eval(&block)
      raise("No filters defined for aspect '#{name}'") if !@filter
      FilterAspect.new(@name, @options, @filter)
    end

    def filter(&block)
      @filter = FilterBuilder.new(@name).build(&block)
      self
    end

    def mime(mime);         @options[:mime] = mime;       self; end
    def accepts(accepts);   @options[:accepts] = accepts; self; end
    def needs_layout;       @options[:layout] = true;     self; end
    def has_priority(prio); @options[:priority] = prio;   self; end
    def is_cacheable;       @options[:cacheable] = true;  self; end
    def is_hidden;          @options[:hidden] = true;     self; end
  end

  # Register regexp filter
  def regexp(name, *regexps)
    Filter.create(name, :description => 'Regular expression filter') do |context, content|
      regexps.each_slice(2) { |regexp, sub| content.gsub!(regexp, sub) }
      content
    end
  end

  # Register aspect
  def aspect(name, &block)
    Aspect.register(AspectBuilder.new(name).build(&block))
    Olelo.logger.debug "Filter aspect '#{name}' successfully created"
  rescue MandatoryFilterNotFound => ex
    Olelo.logger.warn ex.message
  rescue Exception => ex
    Olelo.logger.error ex
  end
end

def setup
  file = File.join(Config['config_path'], 'aspects.rb')
  FilterDSL.new.instance_eval(File.read(file), file)
end
