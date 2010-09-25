module Olelo
  class NotFound < NameError
    def initialize(id)
      super(:not_found.t(:id => id), id)
    end

    def status
      :not_found
    end
  end

  class MultiError < StandardError
    attr_accessor :messages

    def initialize(messages)
      @messages = messages
    end

    def message
      @messages.join(', ')
    end
  end

  module Factory
    def registry
      @registry ||= superclass.try(:registry) || {}
    end

    def register(name, klass)
      name = name.to_s
      raise(ArgumentError, "Implementation '#{name}' already exists for '#{self.name}'") if registry.key?(name)
      registry[name] = klass
    end

    def[](name)
      registry[name.to_s] || raise(NameError, "Implementation '#{name}' for '#{self.name}' not found")
    end
  end

  class BlockFile < ::File
    alias to_path path

    def each
      rewind
      while part = read(8192)
        yield part
      end
    end
  end

  module Util
    def self.included(base)
      base.extend(Util)
    end

    extend self

    def check
      errors = []
      yield(errors)
      raise MultiError, errors if !errors.empty?
    end

    # Like CGI.escape but escapes space not as +
    def escape(s)
      s = s.to_s
      s.gsub(/([^a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end

    # Like CGI.unescape but does not unescape +
    if ''.respond_to? :encoding
      def unescape(s)
        s = s.to_s
        enc = s.encoding
        s.gsub(/((?:%[0-9a-fA-F]{2})+)/) do
          [$1.delete('%')].pack('H*').force_encoding(enc)
        end
      end
    else
      def unescape(s)
        s.to_s.gsub(/((?:%[0-9a-fA-F]{2})+)/) do
          [$1.delete('%')].pack('H*')
        end
      end
    end

    if ''.respond_to? :encoding
      def unescape_backslash(s)
        s = s.to_s
        enc = s.encoding
        s.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr.force_encoding(enc) }.
          gsub(/\\x([\da-f]{2})/i) { $1.to_i(16).chr.force_encoding(enc) }
      end
    else
      def unescape_backslash(s)
        s.to_s.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr }.
          gsub(/\\x([\da-f]{2})/i) { $1.to_i(16).chr }
      end
    end

    def escape_html(s)
      CGI.escapeHTML(s.to_s)
    end

    def unescape_html(s)
      CGI.unescapeHTML(s.to_s)
    end

    JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C' }

    def escape_json(s)
      s.to_s.gsub(/[&><]/) { |x| JSON_ESCAPE[x] }
    end

    def md5(s)
      Digest::MD5.hexdigest(s)
    end

    def sha256(s)
      Digest::SHA256.hexdigest(s)
    end

    def build_query(params)
      params.to_a.map {|k,v| [k.to_s, v ] }.sort.map do |k, v|
        if v.class == Array
          build_query(v.map { |x| [k, x] })
        else
          "#{escape(k.to_s)}=#{escape(v.to_s)}"
        end
      end.join('&')
    end

    def XMLDocument(content)
      Nokogiri::HTML(content, nil, 'UTF-8')
    end

    def XMLFragment(content)
      Nokogiri::HTML::DocumentFragment.new(XMLDocument(nil), content)
    end

    # Hack to create deep copy
    def deep_copy(object)
      Marshal.load(Marshal.dump(object))
    end

    # Decode base64 encoded string
    def decode64(s)
      s.unpack('m').first
    end

    # Encode string as base64
    def encode64(s)
      [s].pack('m').gsub(/\n/, '')
    end

    # Truncate string and add omission
    if ''.respond_to?(:encoding)
      def truncate(s, max, omission = '...')
        s = s.to_s
        (s.length > max ? s[0...max] + omission : s)
      end
    else
      def truncate(s, max, omission = '...')
        s = s.to_s
        if s.length > max
          max += 1 until max >= s.length || valid_xml_chars?(s[0...max])
          s[0...max] + omission
        else
          s
        end
      end
    end

    def capitalize_words(s)
      s.to_s.tr('_', ' ').split(/\s+/).map(&:capitalize).join(' ')
    end

    # See http://www.w3.org/TR/REC-xml/#charsets for details.
    VALID_XML_CHARS = [
      0x9, 0xA, 0xD,
      (0x20..0xD7FF),
      (0xE000..0xFFFD),
      (0x10000..0x10FFFF)
    ]

    # Check if string contains only valid chars
    if ''.respond_to?(:encoding)
      def valid_xml_chars?(s)
        s = s.to_s
        if s.encoding == Encoding::UTF_8
          return false if !s.valid_encoding?
        else
          s = s.dup if s.frozen?
          return false if s.try_encoding(Encoding::UTF_8).encoding != Encoding::UTF_8
        end
        s.codepoints do |n|
          return false if !VALID_XML_CHARS.any? {|v| v === n }
        end
        true
      end
    else
      require 'iconv'
      def valid_xml_chars?(s)
        s = s.to_s
        Iconv.conv('utf-8', 'utf-8', s)
        s.unpack('U*').all? {|n| VALID_XML_CHARS.any? {|v| v === n } }
      rescue
        false
      end
    end

  end
end
