description  'Background worker'

module Olelo::Worker
  def self.start
    @queue = Queue.new
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

def setup
  Worker.start
end
