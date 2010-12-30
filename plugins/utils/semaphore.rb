description 'Semaphore class'

# Semaphore implementation based on {Mutex} and {ConditionVariable}.
# A mutex allows a number of threads to enter a synchronized section in parallel.
class Semaphore
  # @param [Integer] counter Number of threads which can enter the section in parallel
  def initialize(counter = 1)
    @mutex = Mutex.new
    @cond = ConditionVariable.new
    @counter = counter
  end

  # Enter synchronized section
  #
  # Decrements the semaphore counter
  #
  # @api public
  # @return [void]
  def enter
    @mutex.synchronize do
      @cond.wait(@mutex) if (@counter -= 1) < 0
    end
  end

  # Leave synchronized section
  #
  # Increments the semaphore counter
  #
  # @api public
  # @return [void]
  def leave
    @mutex.synchronize do
      @cond.signal if (@counter += 1) <= 0
    end
  end

  # Synchronize block with this semaphore
  #
  # @api public
  # @yield Block to synchronize
  # @return [void]
  def synchronize
    enter
    yield
  ensure
    leave
  end
end

Olelo::Semaphore = Semaphore
