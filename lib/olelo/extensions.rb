class Module
  # Generate accessor method with question mark
  def attr_reader?(*attrs)
    attrs.each do |a|
      module_eval %{ def #{a}?; !!@#{a}; end }
    end
  end

  # From facets
  def attr_setter(*args)
    code, made = '', []
    args.each do |a|
      code << "def #{a}(*a); a.size > 0 ? (@#{a}=a[0]; self) : @#{a} end\n"
      made << a.to_sym
    end
    module_eval(code)
    made
  end

  def redefine_method(name, &block)
    if instance_methods(false).any? {|x| x.to_s == name.to_s }
      method = instance_method(name)
      mod = Module.new do
        define_method(name) {|*args| method.bind(self).call(*args) }
      end
      remove_method(name)
      include(mod)
    end
    include(Module.new { define_method(name, &block) })
  end
end

class Hash
  # Stolen from rails
  class WithIndifferentAccess < Hash
    def initialize(arg = {})
      if Hash === arg
        super()
        update(arg)
      else
        super(arg)
      end
    end

    def default(key = nil)
      if Symbol === key && include?(key = key.to_s)
        self[key]
      else
        super
      end
    end

    alias_method :regular_writer, :[]=
    alias_method :regular_update, :update

    def []=(key, value)
      regular_writer(convert_key(key), value)
      value
    end

    def update(other)
      other.each_pair { |key, value| regular_writer(convert_key(key), value) }
      self
    end

    alias_method :merge!, :update

    def key?(key)
      super(convert_key(key))
    end

    alias_method :include?, :key?
    alias_method :has_key?, :key?
    alias_method :member?, :key?

    def fetch(key, *extras)
      super(convert_key(key), *extras)
    end

    def values_at(*indices)
      indices.collect {|key| self[convert_key(key)]}
    end

    def dup
      WithIndifferentAccess.new(self)
    end

    def merge(hash)
      self.dup.update(hash)
    end

    def delete(key)
      super(convert_key(key))
    end

    def to_hash
      Hash.new(default).merge(self)
    end

    protected

    def convert_key(key)
      Symbol === key ? key.to_s : key
    end
  end

  def with_indifferent_access
    hash = WithIndifferentAccess.new(self)
    hash.default = self.default
    hash
  end

  def self.with_indifferent_access(arg = {})
    WithIndifferentAccess.new(arg)
  end
end

class Object
  def metaclass
    (class << self; self; end)
  end

  # Nice blank? helper from rails activesupport
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # Try to call method if it exists or return nil
  def try(name, *args)
    respond_to?(name) ? send(name, *args) : nil
  end
end

class String
  if ''.respond_to?(:encoding)
    # Try to force encoding and revert to old encoding if this doesn't work
    def try_encoding(new_enc)
      old_enc = encoding
      force_encoding(new_enc)
      force_encoding(old_enc) if !valid_encoding?
      self
    end
  end

  # Unindent string
  def unindent
    result = ''
    each_line {|line| result << line.lstrip }
    result
  end

  # Check if string starts with s
  def starts_with?(s)
    index(s) == 0
  end

  # Check if string ends with s
  def ends_with?(s)
    rindex(s) == size - s.size
  end

  # Clean up path
  def cleanpath
    names = split('/').reject(&:blank?)
    i = 0
    while i < names.length
      case names[i]
      when '..'
        names.delete_at(i)
        if i > 0
          names.delete_at(i-1)
          i -= 1
        end
      when '.'
        names.delete_at(i)
      else
        i += 1
      end
    end
    names.join('/')
  end

  # Concatenate path components
  def /(name)
    "#{self}/#{name}".cleanpath
  end
end
