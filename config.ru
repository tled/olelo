#!/usr/bin/env rackup

path = ::File.expand_path(::File.dirname(__FILE__))
$: << ::File.join(path, 'lib')
Dir[::File.join(path, 'deps', '*', 'lib')].each {|x| $: << x }

# Require newest rack
raise 'Rack 1.2.0 or newer required' if Rack.release < '1.2'

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

Olelo::Config.instance['app_path'] = path
Olelo::Config.instance['config_path'] = ::File.join(path, 'config')
Olelo::Config.instance['initializers_path'] = ::File.join(path, 'config', 'initializers')
Olelo::Config.instance['plugins_path'] = ::File.join(path, 'plugins')
Olelo::Config.instance['views_path'] = ::File.join(path, 'views')
Olelo::Config.instance['themes_path'] = ::File.join(path, 'static', 'themes')
Olelo::Config.instance['cache_store'] = { :type => 'file', 'file.root' => ::File.join(path, '.wiki', 'cache') }
Olelo::Config.instance['authentication.yamlfile.store'] = ::File.join(path, '.wiki', 'users.yml')
Olelo::Config.instance['repository.git'] = { :path => ::File.join(path, '.wiki', 'repository'), :bare => false }
Olelo::Config.instance['log.file'] = ::File.join(path, '.wiki', 'log')
Olelo::Config.instance['rack.session_secret'] = SecureRandom.hex

Olelo::Config.instance.load!(::File.join(path, 'config', 'config.yml.default'))
Olelo::Config.instance.load(ENV['OLELO_CONFIG'] || ENV['WIKI_CONFIG'] || ::File.join(path, 'config', 'config.yml'))
Olelo::Config.instance.freeze

FileUtils.mkpath ::File.dirname(Olelo::Config['log.file'])
logger = ::Logger.new(Olelo::Config['log.file'], :monthly, 10240000)
logger.level = ::Logger.const_get(Olelo::Config['log.level'])

use_lint if !Olelo::Config['production']

use Rack::Runtime
use Rack::ShowExceptions if !Olelo::Config['production']

if Olelo::Config['rack.deflater']
  logger.info 'Use rack deflater'
  use Rack::Deflater
end

use Rack::StaticCache, :urls => ['/static'], :root => path
use Rack::Session::Cookie, :key => 'olelo.session', :secret => Olelo::Config['rack.session_secret']
use Olelo::Middleware::DegradeMimeType

class LoggerOutput
  def initialize(logger); @logger = logger; end
  def write(text); @logger << text; end
end

use Rack::MethodOverride
use Rack::CommonLogger, LoggerOutput.new(logger)

if !Olelo::Config['rack.blacklist'].empty?
  require 'olelo/middleware/blacklist'
  use Olelo::Middleware::Blacklist, :blacklist => Olelo::Config['rack.blacklist']
end

if ''.respond_to? :encoding
  require 'olelo/middleware/force_encoding'
  use Olelo::Middleware::ForceEncoding
end

use Olelo::Middleware::Flash, :set_accessors => %w(error warn info)
use Rack::RelativeRedirect

Olelo::Initializer.initialize(logger)
run Olelo::Application.new

logger.info "Olelo started in #{Olelo::Config['production'] ? 'production' : 'development'} mode"
