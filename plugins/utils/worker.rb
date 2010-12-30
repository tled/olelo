description 'Background worker'
require 'thread'

module Worker
  @queue = Queue.new

  def self.start
    Thread.new do
      loop do
        begin
          user, task = @queue.pop
          User.current = user
          task.call
        rescue => ex
          Olelo.logger.error(ex)
        ensure
          User.current = nil
        end
      end
    end
  end

  def self.jobs
    @queue.length
  end

  def self.defer(&block)
    @queue << [User.current, block]
  end
end

setup do
  Worker.start
end

Olelo::Worker = Worker
