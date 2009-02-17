module Sinatra
  METHODS = %w(get put post delete head)

  module ComplexPatterns
    METHODS.each do |method|
      class_eval %Q{
        def #{method}(path, opts, &block)
          path, keys = replace_complex_patterns(path, opts)
          super(path, opts) do
            c = params[:captures]
            keys.each_with_index {|k,i| params[k] = c ? c[i] : nil }
            instance_eval(&block)
          end
        end
      }
    end

    private

    def replace_complex_patterns(path, opts = {})
      keys = []
      pat = respond_to?(:patterns) ? self.patterns : {}
      pat = pat.merge(opts[:patterns]) if opts.key?(:patterns)
      path.gsub!(/:(\w+)/) do
        keys << key = $1.to_sym
        pat.key?(key) ? "(#{pat[key]})" : '([^/?&#\.]+)'
      end
      return /^#{path}$/, keys
    end
  end

  module MultiplePaths
    METHODS.each do |method|
      class_eval %Q{
        def #{method}(*paths, &block)
          opts = paths.last.is_a?(Hash) ? paths.pop : {}
          paths.each {|path| super(path, opts, &block) }
        end
      }
    end
  end
end

if !Sinatra::Application.respond_to? :patterns
  Sinatra::Application.extend Sinatra::ComplexPatterns
  Sinatra::Application.extend Sinatra::MultiplePaths
end
