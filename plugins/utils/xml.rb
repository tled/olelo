description 'XML support'
require 'nokogiri'

# Nokogiri uses dump_html instead of serialize for broken libxml versions
# Unfortunately this breaks some things here.
# FIXME: Remove this check as soon as nokogiri works correctly.
raise 'The libxml version used by nokogiri is broken, upgrade to 2.7' if Nokogiri.uses_libxml? && %w[2 6] === Nokogiri::LIBXML_VERSION.split('.')[0..1]

class Nokogiri::XML::Node
  OLELO_DEFAULT_XHTML = SaveOptions::FORMAT |
    SaveOptions::NO_DECLARATION |
    SaveOptions::NO_EMPTY_TAGS |
    SaveOptions::AS_XML

  # HACK: Issue https://github.com/sparklemotion/nokogiri/issues/339
  def to_xhtml options = {}
    options[:save_with] |= OLELO_DEFAULT_XHTML if options[:save_with]
    options[:save_with] = OLELO_DEFAULT_XHTML unless options[:save_with]
    serialize(options)
  end
end

module XML
  extend self

  # Parse xml document string and return DOM object (Nokogiri)
  #
  # @param [String] xml document string
  # @return [Nokogiri::HTML::Document] Nokogiri Document
  def Document(xml)
    Nokogiri::HTML(xml, nil, 'UTF-8')
  end

  # Parse xml fragment and return DOM object (Nokogiri)
  #
  # @param [String] xml fragment string
  # @return [Nokogiri::HTML::DocumentFragment] Nokogiri Document Fragment
  def Fragment(xml)
    Nokogiri::HTML::DocumentFragment.new(Document(nil), xml)
  end
end

Olelo::XML = XML
