description 'Aspect subsystem'
dependencies 'utils/cache'

Olelo::Page.attributes do
  enum :aspect do
    Aspect.aspects.keys.inject({}) do |hash, name|
      hash[name] = Olelo::Locale.translate("aspect_#{name}", :fallback => titlecase(name))
      hash
    end
  end
end

# Aspect context
# A aspect context holds the request parameters and other
# variables used by the aspects.
# It is possible for a aspect to run sub-aspects. For this
# purpose you create a subcontext which inherits the variables.
class Olelo::Context
  include Hooks
  has_hooks :initialized

  attr_reader :page, :private, :params, :request, :header

  def initialize(options = {})
    @page     = options[:page]
    @private  = options[:private]  || Hash.with_indifferent_access
    @params   = Hash.with_indifferent_access.merge(options[:params] || {})
    @request  = options[:request]
    @header   = options[:header] || Hash.with_indifferent_access
    invoke_hook(:initialized)
  end

  def [](key)
    private[key]
  end

  def []=(key, value)
    private[key] = value
  end

  def subcontext(options = {})
    Context.new(:page    => options[:page] || page,
                :private => private.merge(options[:private] || {}),
                :params  => params.merge(options[:params] || {}),
                :request => request,
                :header  => header)
  end
end

# An Aspect renders pages
# Aspects get a page as input and create text.
class Olelo::Aspect
  include PageHelper
  include Templates

  @aspects = {}

  class NotAvailable < NameError
    def initialize(name, page)
      super(:aspect_not_available.t(:aspect => name, :page => page.path,
                                    :type => "#{page.mime.comment} (#{page.mime})"))
    end
  end

  # Constructor for aspect
  # Options:
  # * layout: Aspect output should be wrapped in HTML layout (Not used for download/image aspects for example)
  # * priority: Aspect priority. The aspect with the lowest priority will be used for a page.
  # * cacheable: Aspect is cacheable
  def initialize(name, options)
    @name        = name.to_s
    @layout      = !!options[:layout]
    @hidden      = !!options[:hidden]
    @cacheable   = !!options[:cacheable]
    @priority    = (options[:priority] || 99).to_i
    @accepts     = options[:accepts]
    @mime        = options[:mime]
    @plugin      = options[:plugin] || Plugin.current(1)
    @description = options[:description] || @plugin.description
  end

  attr_reader :name, :priority, :mime, :accepts, :description, :plugin
  attr_reader? :layout, :hidden, :cacheable

  # Aspects hash
  def self.aspects
    @aspects
  end

  # Create aspect class. This is sugar to create and
  # register an aspect class in one step.
  def self.create(name, options = {}, &block)
    klass = Class.new(Aspect)
    klass.class_eval(&block)
    register klass.new(name, options)
  end

  # Register aspect instance
  def self.register(aspect)
    (@aspects[aspect.name] ||= []) << aspect
  end

  # Find all accepting aspects for a page
  def self.find_all(page)
    @aspects.values.map do |aspects|
      aspects.sort_by {|e| e.priority }.find {|e| e.accepts?(page) }
    end.compact
  end

  # Find appropiate aspect for page. An optional
  # name can be given to claim a specific aspect.
  # If no aspect is found a exception is raised.
  def self.find!(page, options = {})
    options[:name] ||= page.attributes['aspect']
    aspects = options[:name] ? @aspects[options[:name].to_s] : @aspects.values.flatten
    aspect = aspects.to_a.sort_by {|e| e.priority }.find { |e| e.accepts?(page) && (!options[:layout] || e.layout?) }
    raise NotAvailable.new(options[:name], page) if !aspect
    aspect.dup
  end

  # Find appropiate aspect for page. An optional
  # name can be given to claim a specific aspect.
  # If no aspect is found nil is returned.
  def self.find(page, options = {})
    find!(page, options) rescue nil
  end

  # Acceptor should return true if page would be accepted by this aspect.
  # Reimplement this method.
  def accepts?(page)
    page.mime.to_s =~ /#{@accepts}/
  end

  # Render page content.
  # Reimplement this method.
  def call(context, page)
    raise NotImplementedError
  end
end

# Plug-in the aspect subsystem
module Olelo::PageHelper
  def include_page(path)
    page = Page.find(path) rescue nil
    if page
      Cache.cache("include-#{page.path}-#{page.version.cache_id}", :update => request.no_cache?, :defer => true) do |context|
        begin
          context = Context.new(:page => page, :params => {:included => true})
          Aspect.find!(page, :layout => true).call(context, page)
        rescue Aspect::NotAvailable => ex
          %{<span class="error">#{escape_html ex.message}</span>}
        end
      end
    else
      %{<a href="#{escape_html absolute_path('new'/path)}">#{escape_html :create_page.t(:page => path)}</a>}
    end
  end
end

# Plug-in the aspect subsystem
class Olelo::Application
  def show_page
    params[:aspect] ||= 'subpages' if params[:path].to_s.ends_with? '/'
    @selected_aspect, layout, header, content =
      Cache.cache("aspect-#{page.path}-#{page.version.cache_id}-#{build_query(original_params)}",
                  :update => request.no_cache?, :defer => true) do |cache|
      aspect = Aspect.find!(page, :name => params[:aspect])
      cache.disable! if !aspect.cacheable?
      context = Context.new(:page => page, :params => params, :request => request)
      result = aspect.call(context, page)
      context.header['Content-Type'] ||= aspect.mime.to_s if aspect.mime
      context.header['Content-Type'] ||= page.mime.to_s if !aspect.layout?
      [aspect.name, aspect.layout?, context.header.to_hash, result]
    end
    self.response.header.merge!(header)

    @menu_versions = true
    halt(layout ? render(:show, :locals => {:content => content}) : content)
  rescue Aspect::NotAvailable => ex
    cache_control :no_cache => true
    redirect absolute_path(page) if params[:path].to_s.ends_with? '/'
    raise if params[:aspect]
    flash.error ex.message
    redirect action_path(page, :edit)
  end

  hook :dom do |name, doc, layout|
    doc.css('#menu .action-view').each do |link|
      menu = Cache.cache("aspect-menu-#{page.path}-#{page.version.cache_id}-#{@selected_aspect}",
                         :update => request.no_cache?, :defer => true) do
        aspects = Olelo::Aspect.find_all(page).select {|e| !e.hidden? || e.name == @selected_aspect }.map do |e|
          [Olelo::Locale.translate("aspect_#{e.name}", :fallback => titlecase(e.name)), e]
        end.sort_by(&:first)
        li = []
        aspects.select {|name, e| e.layout? }.each do |name, e|
          li << %{<li#{e.name == @selected_aspect ? ' class="selected"': ''}>
                  <a href="#{escape_html page_path(page, :aspect => e.name)}">#{escape_html name}</a></li>}.unindent
        end
        aspects.reject {|name, e| e.layout? }.each do |name, e|
          li << %{<li class="download"><a href="#{escape_html page_path(page, :aspect => e.name)}">#{escape_html name}</a></li>}
        end
        "<ul>#{li.join}</ul>"
      end
      link.after(menu)
    end
  end
end
