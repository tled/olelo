description 'Shell utility'
require 'shellwords'

class Olelo::Shell
  def run(data = nil)
    cmd = @cmd.join(' | ')
    return `#{cmd}` if !data
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      output = ''
      len = 0
      begin
        while len < data.length
          if found = IO.select([stdout], [stdin], nil, 0)
            len += stdin.write_nonblock(data[len..-1]) if found[1].first
            output << stdout.read_nonblock(1048576) if found[0].first && !stdout.eof?
          end
        end
      rescue Errno::EPIPE
      end
      stdin.close
      begin
        output << stdout.read
      rescue Errno::EAGAIN
        retry
      end
      output
    end
  end

  def cmd(*args)
    yield(args) if block_given?
    (@cmd ||= []) << args.compact.map(&:to_s).shelljoin
    self
  end

  def method_missing(*args, &block)
    cmd(*args, &block)
  end

  def self.method_missing(*args, &block)
    new.send(*args, &block)
  end
end
