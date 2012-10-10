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

    def modify(&block)
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
        errors << :invalid_name.t  if name !~ /[\w\.\-\+_]+/
      end
    end

    class Service
      include Util
      extend Factory

      class NotSupportedError < AuthenticationError
        def initialize(name)
          super(:auth_unsupported.t(:name => name))
        end
      end

      def find(name)
        raise NotImplementedError
      end

      def authenticate(name, password)
        raise NotImplementedError
      end

      def create(user, password)
        raise NotSupportedError('create')
      end

      def update(user)
        raise NotSupportedError('update')
      end

      def change_password(user, oldpassword, password)
        raise NotSupportedError('change_password')
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
        name = request.remote_host ? "#{request.remote_host} (#{ip})" : ip
        new(name, "anonymous@#{ip}")
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

      def create(name, password, confirm, email)
        validate_password(password, confirm)
        user = new(name, email, %w(user))
        user.validate
        service.create(user, password)
        user
      end
    end

  end
end
