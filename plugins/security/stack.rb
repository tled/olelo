description 'Authentication service stack'

class StackService < User::Service
  def initialize(config)
    @stack = config.map do |name|
      User::Service[name].new(Config.authentication[name])
    end
  end

  # @override
  def authenticate(name, password)
    @stack.any? do |service|
      user = service.authenticate(name, password) rescue nil
      return user if user
    end
    raise AuthenticationError, :wrong_user_or_pw.t
  end
end

User::Service.register :stack, StackService
