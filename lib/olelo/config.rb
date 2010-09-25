module Olelo
  class Config
    include Enumerable

    attr_reader :base, :hash
    undef_method :type rescue nil if RUBY_VERSION < '1.9'

    def initialize(hash = nil, base = nil)
      @hash = {}
      @base = base
      update(hash) if hash
    end

    def[](key)
      key = key.to_s
      i = key.index('.')
      if i
        _not_found(key) if !hash.include?(key[0...i])
        hash[key[0...i]][key[i+1..-1]]
      else
        _not_found(key) if !hash.include?(key)
        hash[key]
      end
    end

    def []=(key, value)
      key = key.to_s
      i = key.index('.')
      if i
        _child(key[0...i])[key[i+1..-1]] = value
      elsif Hash === value
        _child(key).update(value)
      else
        _create_accessor(key)
        hash[key] = value
      end
    end

    def update(hash)
      hash.each_pair do |key, value|
        self[key] = value
      end
    end

    def method_missing(key, *args)
      _not_found(key)
    end

    def load(file)
      load!(file) if File.file?(file)
    end

    def load!(file)
      update(YAML.load_file(file))
    end

    def each(&block)
      hash.each(&block)
    end

    def self.instance
      @instance ||= Config.new
    end

    def self.method_missing(key, *args)
      instance.send(key, *args)
    end

    def to_hash
      hash = Hash.with_indifferent_access
      each do |k, v|
        hash[k] = Config === v ? v.to_hash : v
      end
      hash
    end

    private

    def _not_found(key)
      raise(NameError, "Configuration key #{base ? "#{base}.#{key}" : key} not found")
    end

    def _child(key)
      _create_accessor(key)
      hash[key] ||= Config.new(nil, base ? "#{base}.#{key}" : key)
    end

    def _create_accessor(key)
      if !respond_to?(key)
        metaclass.class_eval do
          define_method("#{key}?") { !!hash[key] }
          define_method(key) { hash[key] }
          define_method("#{key}=") { |x| hash[key] = x }
        end
      end
    end

  end
end
