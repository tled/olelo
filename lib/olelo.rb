require 'logger'
require 'cgi'
require 'digest/md5'
require 'digest/sha2'
require 'open3'
require 'set'
require 'yaml'
require 'mimemagic'

begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

require 'olelo/html_safe'
require 'slim'

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
require 'olelo/menu'
require 'olelo/helper'
require 'olelo/repository'
require 'olelo/attributes'
require 'olelo/page'
require 'olelo/plugin'
require 'olelo/patch'
require 'olelo/initializer'
require 'olelo/application'

raise "Your Ruby version is too old (1.8.7 is required)" if RUBY_VERSION < '1.8.7'

# Ruby 1.9.1 uses different constant name resolution (reverted in 1.9.2 to 1.8.7 behaviour)
raise "Ruby 1.9.0 and 1.9.1 are unsupported" if RUBY_VERSION == '1.9.0' || RUBY_VERSION == '1.9.1'
