require 'rack'
require 'socket'

class Rack::Request
  # Remote host name
  def remote_host
    @remote_host ||= Socket.gethostbyaddr(ip.split('.').map(&:to_i).pack('C*')).first rescue nil
  end

  # No caching for this request?
  def no_cache?
    env['HTTP_PRAGMA'] == 'no-cache' || env['HTTP_CACHE_CONTROL'].to_s.include?('no-cache')
  end
end
