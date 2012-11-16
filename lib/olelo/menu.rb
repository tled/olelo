module Olelo
  class Menu
    include Util
    include Enumerable
    attr_reader :name

    def initialize(name)
      @name = name.to_sym
      @items = {}
    end

    def each(&block)
      @items.each_value(&block)
    end

    def [](name)
      path = path.to_s
      i = path.index('/')
      if i
        item = @items[path[0...i]]
        item[path[i+1..-1]] if item
      else
        @items[name.to_sym]
      end
    end

    def item(name, options = {})
      self << MenuItem.new(name, options)
    end

    def append(items)
      items.each {|item| self << item }
    end

    def <<(item)
      raise TypeError, "Only items allowed" unless MenuItem === item
      raise "Item #{item.name} exists already in #{path.join('/')}" if @items.include?(item.name)
      item.parent = self
      @items[item.name] = item
    end

    def empty?
      @items.empty?
    end

    def clear
      @items.clear
    end

    def remove(name)
      path = name.to_s
      i = path.index('/')
      if i
        item = @items[path[0...i]]
        item.remove(path[i+1..-1]) if item
      else
        @items.delete(name.to_sym)
      end
    end

    def build_menu
      empty? ? '' : %{<ul id="menu-#{html_id}">#{map(&:build_menu).join}</ul>}
    end

    def to_html
      build_menu.html_safe
    end

    def html_id
      escape_html path.join('-')
    end

    def path
      [name]
    end
  end

  class MenuItem < Menu
    attr_reader :options
    attr_accessor :parent

    def initialize(name, options = {})
      super(name)
      @parent = nil
      @options = options
    end

    def path
      parent ? parent.path << super : super
    end

    def build_menu
      attrs = options.dup
      label = attrs.delete(:label) || Locale.translate("menu_#{path.join('_')}", fallback: titlecase(name))
      klass = [*attrs.delete(:class)].flatten.compact
      klass = klass.empty? ? '' : %{class="#{klass.join(' ')}" }
      attrs = attrs.map {|k,v| %{#{k}="#{escape_html v}"} }.join(' ')
      %{<li #{klass}id="item-#{html_id}"><a #{attrs}>#{escape_html label}</a>#{super}</li>}
    end
  end
end
