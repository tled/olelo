require 'olelo'
require 'bacon'
require 'rack/test'

module TestHelper
  def load_plugin(*plugins)
    Olelo.logger = Logger.new(File.expand_path(File.join(File.dirname(__FILE__), '..', 'test.log')))
    Olelo::Plugin.dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugins'))
    Olelo::Plugin.load(*plugins)
  end

  def create_repository
    Thread.current[:olelo_repository] = nil
    Olelo::User.current = Olelo::User.new('anonymous', 'anonymous@localhost')
    load_plugin('repositories/rugged_repository')
    Olelo::Config.instance['repository.type'] = 'git'
    Olelo::Config.instance['repository.git.path'] = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    Olelo::Config.instance['repository.git.bare'] = true
  end

  def destroy_repository
    FileUtils.rm_rf(Olelo::Config['repository.git.path'])
    Thread.current[:olelo_repository] = nil
    Olelo::User.current = nil
  end

  def create_page(name, content = 'content')
    Olelo::Page.transaction do
      page = Olelo::Page.new(name)
      page.content = content
      page.save
      Olelo::Page.commit('comment')
    end
  end
end

class Bacon::Context
  include TestHelper
end
