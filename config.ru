#!/usr/bin/env rackup

path = ::File.expand_path(::File.dirname(__FILE__))
$: << ::File.join(path, 'lib')
Dir[::File.join(path, 'deps', '*', 'lib')].each {|x| $: << x }

# Require newest rack
raise 'Rack 1.1.0 or newer required' if Rack.version < '1.1'

# We want to read all text data as UTF-8
Encoding.default_external = Encoding::UTF_8 if ''.respond_to? :encoding

require 'fileutils'
require 'rack/olelo_patches'
require 'rack/relative_redirect'
require 'rack/static_cache'
require 'olelo'
require 'olelo/middleware/degrade_mime_type'
require 'olelo/middleware/flash'
require 'securerandom'

Olelo::Config['app_path'] = path
Olelo::Config['config_path'] = ::File.join(path, 'config')
Olelo::Config['initializers_path'] = ::File.join(path, 'config', 'initializers')
Olelo::Config['plugins_path'] = ::File.join(path, 'plugins')
Olelo::Config['views_path'] = ::File.join(path, 'views')
Olelo::Config['themes_path'] = ::File.join(path, 'static', 'themes')
Olelo::Config['tmp_path'] = ::File.join(path, '.wiki', 'tmp')
Olelo::Config['cache_store'] = { :type => 'file', 'file.root' => ::File.join(path, '.wiki', 'tmp', 'cache') }
Olelo::Config['authentication.yamlfile.store'] = ::File.join(path, '.wiki', 'users.yml')
Olelo::Config['tokens_store'] = { :type => 'pstore', 'pstore.file' => ::File.join(path, '.wiki', 'tmp', 'tokens.pstore') }
Olelo::Config['repository.git'] = { :path => ::File.join(path, '.wiki', 'repository'), :bare => false }
Olelo::Config['log.file'] = ::File.join(path, '.wiki', 'log')
Olelo::Config['rack.session_secret'] = SecureRandom.hex

Olelo::Config.load!(::File.join(path, 'config', 'config.yml.default'))
Olelo::Config.load(ENV['OLELO_CONFIG'] || ENV['WIKI_CONFIG'] || ::File.join(path, 'config', 'config.yml'))

FileUtils.mkpath Olelo::Config.tmp_path, :mode => 0755
FileUtils.mkpath ::File.dirname(Olelo::Config.log.file), :mode => 0755

logger = ::Logger.new(Olelo::Config.log.file, 25, 1024000)
logger.level = ::Logger.const_get(Olelo::Config.log.level)

use_lint if !Olelo::Config.production?

use Rack::Runtime
use Rack::ShowExceptions if !Olelo::Config.production?

if !Olelo::Config.rack.blacklist.empty?
  require 'olelo/middleware/blacklist'
  use Olelo::Middleware::Blacklist, :blacklist => Olelo::Config.rack.blacklist
end

use Olelo::Middleware::DegradeMimeType
use Rack::RelativeRedirect

if Olelo::Config.rack.deflater?
  logger.info 'Use rack deflater'
  use Rack::Deflater
end

use Rack::StaticCache, :urls => ['/static'], :root => path
use Rack::Session::Cookie, :key => 'olelo.session', :secret => Olelo::Config.rack.session_secret
use Olelo::Middleware::Flash, :sweep => true, :array_accessors => %w(error warn info)

class LoggerOutput
  def initialize(logger); @logger = logger; end
  def write(text); @logger << text; end
end

use Rack::MethodOverride
use Rack::CommonLogger, LoggerOutput.new(logger)

if ''.respond_to? :encoding
  require 'olelo/middleware/force_encoding'
  use Olelo::Middleware::ForceEncoding
end

run Olelo::Application.new(nil, :logger => logger)

logger.info "Olelo started in #{Olelo::Config.production? ? 'production' : 'development'} mode"
