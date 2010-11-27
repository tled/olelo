module Olelo
  class Menu
    include Util
    include Enumerable
    attr_reader :name

    def initialize(name)
      @name = name.to_sym
      @items = []
      @items_map = {}
    end

    def each(&block)
      @items.each(&block)
    end

    def [](name)
      path = path.to_s
      i = path.index('/')
      if i
        item = @items_map[path[0...i]]
        item[path[i..-1]] if item
      else
        @items_map[name.to_sym]
      end
    end

    def item(name, options = {})
      self << MenuItem.new(name, options)
    end

    def <<(item)
      raise TypeError, "Only items allowed" unless MenuItem === item
      raise "Item #{item.name} exists already in #{path.join('/')}" if @items_map.include?(item.name)
      item.parent = self
      @items << item
      @items_map[item.name] = item
    end

    def empty?
      @items.empty?
    end

    def clear
      @items.clear
      @items_map.clear
    end

    def remove(name)
      path = name.to_s
      i = path.index('/')
      if i
        item = @items_map[path[0...i]]
        item.remove(path[i..-1]) if item
      else
        item = @items_map.delete(name.to_sym)
        @items.delete(item) if item
      end
    end

    def build_menu
      empty? ? '' : %{<ul id="menu-#{html_id}">#{map {|item| item.build_menu }.join}</ul>}
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
      label = attrs.delete(:label) || Locale.translate("menu_#{path.join('_')}", :fallback => titlecase(name))
      klass = [*attrs.delete(:class)].flatten.compact
      klass = klass.empty? ? '' : %{class="#{klass.join(' ')}" }
      attrs = attrs.map {|k,v| %{#{k}="#{escape_html v}"} }.join(' ')
      %{<li #{klass}id="item-#{html_id}"><a #{attrs}>#{escape_html label}</a>#{super}</li>}
    end
  end
end
