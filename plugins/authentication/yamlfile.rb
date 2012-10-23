description 'YAML based user storage'
require 'yaml/store'

class YamlfileService < User::Service
  def initialize(config)
    FileUtils.mkpath(File.dirname(config[:store]))
    @store = ::YAML::Store.new(config[:store])
  end

  # @override
  def find(name)
    @store.transaction(true) do |store|
      user = store[name]
      user && User.new(name, user['email'], user['groups'])
    end
  end

  # @override
  def authenticate(name, password)
    @store.transaction(true) do |store|
      user = store[name]
      raise AuthenticationError, :wrong_user_or_pw.t if !user || user['password'] != crypt(password)
      User.new(name, user['email'], user['groups'])
    end
  end

  # @override
  def signup(user, password)
    @store.transaction do |store|
      raise :user_already_exists.t(name: user.name) if store[user.name]
      store[user.name] = {
        'email' => user.email,
        'password' => crypt(password),
	'groups' => user.groups.to_a
      }
    end
  end

  # @override
  def update(user)
    @store.transaction do |store|
      raise NameError, "User #{user.name} not found" if !store[user.name]
      store[user.name]['email'] = user.email
      store[user.name]['groups'] = user.groups.to_a
    end
  end

  # @override
  def change_password(user, oldpassword, password)
    @store.transaction do |store|
      check do |errors|
        errors << 'User not found' if !store[user.name]
        errors << :wrong_password.t if crypt(oldpassword) != store[user.name]['password']
      end
      store[user.name]['password'] = crypt(password)
    end
  end

  private

  def crypt(s)
    s.blank? ? s : sha256(s)
  end
end

User::Service.register :yamlfile, YamlfileService
