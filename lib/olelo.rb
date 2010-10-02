require 'logger'
require 'cgi'
require 'digest/md5'
require 'digest/sha2'
require 'open3'
require 'set'
require 'yaml'
require 'mimemagic'
require 'haml'

# Nokogiri uses dump_html instead of serialize for broken libxml versions
# Unfortunately this breaks some things here.
# FIXME: Remove this check as soon as nokogiri works correctly.
require 'nokogiri'
raise 'The libxml version used by nokogiri is broken, upgrade to 2.7' if Nokogiri.uses_libxml? && %w[2 6] === Nokogiri::LIBXML_VERSION.split('.')[0..1]

begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

require 'olelo/compatibility'
require 'olelo/extensions'
require 'olelo/util'
require 'olelo/locale'
require 'olelo/hooks'
require 'olelo/config'
require 'olelo/routing'
require 'olelo/user'
require 'olelo/virtualfs'
require 'olelo/templates'
require 'olelo/helper'
require 'olelo/repository'
require 'olelo/attributes'
require 'olelo/page'
require 'olelo/plugin'
require 'olelo/patch'
require 'olelo/initializer'
require 'olelo/application'
