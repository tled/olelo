require 'rack/olelo_patches'
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
    Olelo::Repository.instance = nil
    Olelo::Config.instance['repository.type'] = 'git'
    Olelo::Config.instance['repository.git.path'] = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    Olelo::Config.instance['repository.git.bare'] = true
    load_plugin('repository/git/repository')
  end

  def destroy_repository
    Olelo::Repository.instance = nil
    FileUtils.rm_rf(Olelo::Config['repository.git.path'])
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
