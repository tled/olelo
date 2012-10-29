description 'XML support'
require 'nokogiri'

# Nokogiri uses dump_html instead of serialize for broken libxml versions
# Unfortunately this breaks some things here.
# FIXME: Remove this check as soon as nokogiri works correctly.
raise 'The libxml version used by nokogiri is broken, upgrade to 2.7' if Nokogiri.uses_libxml? && %w[2 6] === Nokogiri::LIBXML_VERSION.split('.')[0..1]

class Nokogiri::XML::Node
  def to_xhtml
    # HACK: Issue https://github.com/sparklemotion/nokogiri/issues/339
    serialize Nokogiri::XML::Node::SaveOptions::NO_DECLARATION |
      Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS |
      Nokogiri::XML::Node::SaveOptions::AS_XHTML
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
