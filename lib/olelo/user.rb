module Olelo
  class AuthenticationError < RuntimeError
    def status
      :forbidden
    end
  end

  class AccessDenied < RuntimeError
    def initialize
      super(:access_denied.t)
    end

    def status
      :forbidden
    end
  end

  class User
    include Util
    attr_reader :name, :groups
    attr_accessor :email

    def initialize(name, email, groups = nil)
      @name, @email, @groups = name, email, Set.new(groups.to_a)
    end

    def change_password(oldpassword, password, confirm)
      User.validate_password(password, confirm)
      User.service.change_password(self, oldpassword, password)
    end

    def update(&block)
      copy = dup
      block.call(copy)
      validate
      User.service.update(copy)
      instance_variables.each do |name|
        instance_variable_set(name, copy.instance_variable_get(name))
      end
    end

    def validate
      check do |errors|
        errors << :invalid_email.t if email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        errors << :invalid_name.t  if name !~ /[\w\.\-\+]+/
      end
    end

    class Service
      include Util
      extend Factory

      def find(name)
        raise NotImplementedError
      end

      def authenticate(name, password)
        raise NotImplementedError
      end
    end

    class<< self
      def current
        Thread.current[:olelo_user]
      end

      def current=(user)
        Thread.current[:olelo_user] = user
      end

      def logged_in?
        current && current.groups.include?('user')
      end

      def service
        @service ||= Service[Config['authentication.service']].new(Config['authentication'][Config['authentication.service']])
      end

      def validate_password(password, confirm)
        check do |errors|
          errors << :passwords_do_not_match.t if password != confirm
          errors << :empty_password.t if password.blank?
        end
      end

      def anonymous(request)
        ip = request.ip || 'unknown-ip'
        host = request.ip && Socket.gethostbyaddr(request.ip.split('.').map(&:to_i).pack('C*')).first rescue nil
        new(host ? "#{host} (#{ip})" : ip, "anonymous@#{ip}")
      end

      def find!(name)
        service.find(name)
      end

      def find(name)
        find!(name) rescue nil
      end

      def authenticate(name, password)
        service.authenticate(name, password).tap {|user| user.groups << 'user' }
      end

      def supports?(method)
        service.respond_to?(method)
      end

      def signup(name, password, confirm, email)
        validate_password(password, confirm)
        user = new(name, email, %w(user))
        user.validate
        service.signup(user, password)
        user
      end
    end

  end
end
