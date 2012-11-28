# encoding: UTF-8
require 'helper'

describe 'Olelo::Util' do
  it 'should have #check' do
    Olelo::Util.check do |errors|
      # do nothing
    end
    lambda do
      Olelo::Util.check do |errors|
        errors << 'Error 1'
        errors << 'Error 2'
      end
    end.should.raise Olelo::MultiError
  end

  it 'should have #escape which escapes space as %20' do
    Olelo::Util.escape('+@ ').should.equal '%2B%40%20'
  end

  it 'should have #unescape which does not unescape +' do
    Olelo::Util.unescape('+%20+').should.equal '+ +'
  end

  it 'should have #escape_html' do
    Olelo::Util.escape_html('<').should.equal '&lt;'
  end

  it 'should have #unescape_html' do
    Olelo::Util.unescape_html('&lt;').should.equal '<'
  end

  it 'should have #escape_javascript' do
    Olelo::Util.escape_javascript('a&b<c>').should.equal 'a\u0026b\u003Cc\u003E'
  end

  it 'should have #md5' do
    Olelo::Util.md5('test').should.equal '098f6bcd4621d373cade4e832627b4f6'
  end

  it 'should have #sha256' do
    Olelo::Util.sha256('test').should.equal '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'
  end

  it 'should have #truncate' do
    Olelo::Util.truncate('Annabel Lee It was many and many a year ago', 11).should.equal 'Annabel Lee...'
    Olelo::Util.truncate('In a kingdom by the sea', 39).should.equal 'In a kingdom by the sea'
    Olelo::Util.truncate("\346\254\242\350\277\216\350\277\233\345\205\245", 1).should.equal "\346\254\242..."
  end

  it 'should have #titlecase' do
    Olelo::Util.titlecase(:hello_world).should.equal 'Hello World'
    Olelo::Util.titlecase('hello_world').should.equal 'Hello World'
    Olelo::Util.titlecase('hello world').should.equal 'Hello World'
  end

  it 'should have #valid_xml_chars?' do
    Olelo::Util.valid_xml_chars?('test').should.equal true
    Olelo::Util.valid_xml_chars?("\346\254\242\350\277\216\350\277\233\345\205\245").should.equal true
    Olelo::Util.valid_xml_chars?("\032").should.equal false
  end
end
