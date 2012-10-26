require 'helper'

describe 'Olelo::Page' do
  before { create_repository }
  after { destroy_repository }

  it 'check for path validity' do
    lambda do
      Olelo::Page.check_path(' spaces ')
    end.should.raise RuntimeError
    Olelo::Page.check_path('spaces in the path')
  end

  it 'should have no root before the first page is created' do
    Olelo::Page.find('').should.equal nil
    create_page('Home')
    Olelo::Page.find('').should.be.an.instance_of Olelo::Page
  end

  it 'find or raise' do
    lambda { Olelo::Page.find!('') }.should.raise Olelo::NotFound
    create_page('Home')
    Olelo::Page.find('').should.be.an.instance_of Olelo::Page
    Olelo::Page.find('Home').should.be.an.instance_of Olelo::Page
  end

  it 'should be new' do
    create_page('Home')
    Olelo::Page.find('Home').should.not.be.new
    Olelo::Page.find('').should.not.be.new
    Olelo::Page.new('new').should.be.new
    Olelo::Page.new('new').should.be.new
  end

  it 'has name' do
    Olelo::Page.new('/path/name.ext').name.should.equal 'name.ext'
  end

  it 'has path' do
    Olelo::Page.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'should have correct path' do
    Olelo::Page.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'should have correct extension' do
    Olelo::Page.new('/path/name.tar.gz').extension.should.equal 'tar.gz'
  end

  it 'write content' do
    page = Olelo::Page.new('test')
    page.should.be.new
    page.should.not.be.modified
    page.content.should.equal ''
    Olelo::Page.transaction do
      page.content = 'old content'
      page.save
      Olelo::Page.commit "comment1\ntext"
    end

    page.content.should.equal 'old content'
    page.should.not.be.new
    page.should.not.be.modified

    page.tree_version.comment.should.equal "comment1\ntext"

    page.content = 'new content'
    page.should.not.be.new
    page.should.be.modified
    page.content.should.equal 'new content'
    Olelo::Page.transaction do
      page.content = 'new content'
      page.save
      Olelo::Page.commit 'comment2'
    end

    page.tree_version.comment.should.equal 'comment2'

    page = Olelo::Page.find!('test')
    page.should.not.be.new
    page.content.should.equal 'new content'

    page.tree_version.comment.should.equal 'comment2'
  end

  it 'fail on duplicates' do
    Olelo::Page.transaction do
      page = Olelo::Page.new('test')
      page.content = 'content'
      page.save
      Olelo::Page.commit 'comment'
    end

    lambda do
      Olelo::Page.transaction do
        page = Olelo::Page.new('test')
        page.content = 'content'
        page.save
        Olelo::Page.commit 'comment'
      end
    end.should.raise RuntimeError
  end

  it 'should have children' do
    create_page('page1')
    create_page('page2')
    create_page('page3')

    tree = Olelo::Page.find!('/')
    tree.tree_version.should.be.head

    tree.tree_version.should.equal tree.children[0].tree_version
    tree.tree_version.should.equal tree.children[1].tree_version
    tree.tree_version.should.equal tree.children[2].tree_version
    tree.children[0].tree_version.should.be.head
    tree.children[1].tree_version.should.be.head
    tree.children[2].tree_version.should.be.head

    old_tree = Olelo::Page.find('/', tree.previous_version)
    old_tree.tree_version.should.not.be.head
    tree.previous_version.should.equal old_tree.tree_version
    old_tree.tree_version.should.equal old_tree.children[0].tree_version
    old_tree.tree_version.should.equal old_tree.children[1].tree_version
    old_tree.children[2].should.equal nil
    old_tree.children[0].tree_version.should.not.be.head
  end

  it 'has working children' do
    create_page('tree1/subpage1')
    create_page('tree1/subpage2')
    create_page('tree1/subpage3')
    create_page('tree2/subpage1')
    create_page('tree2/subpage2')
    create_page('tree2/subpage3')
    create_page('tree3/subpage1')
    create_page('tree3/subpage2')
    create_page('tree3/subpage3')
    create_page('tree1/subtree1/subsubpage1')
    create_page('tree1/subtree1/subsubpage2')
    create_page('tree1/subtree1/subsubpage3')
    create_page('page1')
    create_page('page2')
    create_page('page3')

    tree = Olelo::Page.find!('/')
    tree.children.size.should.equal 6
    tree.children[0].path.should.equal 'page1'
    tree.children[1].path.should.equal 'page2'
    tree.children[2].path.should.equal 'page3'
    tree.children[3].path.should.equal 'tree1'
    tree.children[4].path.should.equal 'tree2'
    tree.children[5].path.should.equal 'tree3'

    tree = Olelo::Page.find!('/tree1')
    tree.children.size.should.equal 4
    tree.children[0].path.should.equal 'tree1/subpage1'
    tree.children[1].path.should.equal 'tree1/subpage2'
    tree.children[2].path.should.equal 'tree1/subpage3'
    tree.children[3].path.should.equal 'tree1/subtree1'

    tree = Olelo::Page.find!('/tree1/subtree1')
    tree.children.size.should.equal 3
    tree.children[0].path.should.equal 'tree1/subtree1/subsubpage1'
    tree.children[1].path.should.equal 'tree1/subtree1/subsubpage2'
    tree.children[2].path.should.equal 'tree1/subtree1/subsubpage3'
  end
end
