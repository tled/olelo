module Olelo
  # Simple localization implementation
  module Locale
    @locale = nil
    @translations = Hash.with_indifferent_access
    @loaded = []

    class << self
      attr_accessor :locale

      # Load locale from file
      #
      # A locale is a yamlfile which maps
      # keys to strings.
      #
      # @param [String] file name
      # @return [void]
      #
      def load(file)
        if !@loaded.include?(file) && File.file?(file)
          locale = YAML.load_file(file)
          @translations.update(locale[$1] || {}) if @locale =~ /^(\w+)(_|-)/
          @translations.update(locale[@locale] || {})
          @translations.each_value(&:freeze)
          @loaded << file
        end
      end

      # Return translated string for key
      #
      # A translated string can contain variables which are substituted in this method.
      # You have to pass an arguments hash.
      #
      # @option args [Integer] :count    if count is not 1, the key #{key}_plural is looked up instead
      # @option args [String]  :fallback Fallback string if key is not found in the locale
      # @param [Symbol, String] key which identifies string in locale
      # @param [Hash] args Arguments hash for string interpolation
      # @return [String] translated string
      #
      def translate(key, args = {})
        if !key.to_s.ends_with?('_plural') && args[:count] && args[:count] != 1
          translate("#{key}_plural", args)
        elsif @translations[key]
          @translations[key] % args
        else
          args[:fallback] || "##{key}"
        end
      end
    end
  end
end

class Symbol
  # Lookup translated string identified by this symbol
  #
  # @param [Hash] args Arguments hash for string interpolation
  # @return [String] translated string
  # @see Olelo::Locale#translate
  #
  def t(args = {})
    Olelo::Locale.translate(self, args)
  end
end
