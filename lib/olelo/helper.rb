# -*- coding: utf-8 -*-
module Olelo
  module BlockHelper
    def blocks
      @blocks ||= Hash.with_indifferent_access('')
    end

    def define_block(name, content = nil)
      blocks[name] = block_given? ? yield : escape_html(content)
      ''
    end

    def include_block(name)
      with_hooks(name) { blocks[name] }.join.html_safe
    end

    def render_block(name)
      with_hooks(name) { yield }.join.html_safe
    end

    def include_or_define_block(name, content = nil, &block)
      if block_given? || content
        define_block(name, content, &block)
      else
        include_block(name)
      end
    end
  end

  module FlashHelper
    include Util

    def flash
      env['olelo.flash']
    end

    def flash_messages
      li = [:error, :warn, :info].map {|level| flash[level].to_a.map {|msg| %{<li class="#{level}">#{escape_html msg}</li>} } }.flatten
      %{<ul class="flash">#{li.join}</ul>}.html_safe if !li.empty?
    end
  end

  module PageHelper
    include Util

    def include_page(path)
      page = Page.find(path) rescue nil
      if page
        render_page(page)
      else
        %{<a href="#{escape_html build_path(path, action: :new)}">#{escape_html :create_page.t(page: path)}</a>}
      end
    end

    def render_page(page)
      page.content
    end

    def pagination(path, page_count, page_nr, options = {})
      return if page_count <= 1
      unlimited = options.delete(:unlimited)
      li = []
      li << if page_nr > 1
              %{<a href="#{escape_html build_path(path, options.merge(page: page_nr - 1))}">&#9666;</a>}
            else
              %{<span class="disabled">&#9666;</span>}
            end
      min = page_nr - 3
      max = page_nr + 3
      if min > 1
        min -= max - page_count if max > page_count
      else
        max -= min if min < 1
      end
      max = max + 2 < page_count ? max : page_count
      min = min > 3 ? min : 1
      if min != 1
        li << %{<a href="#{escape_html build_path(path, options.merge(page: 1))}">1</a>} << %{<span class="ellipsis"/>}
      end
      (min..max).each do |i|
        li << if i == page_nr
                %{<span class="current">#{i}</span>}
              else
                %{<a href="#{escape_html build_path(path, options.merge(page: i))}">#{i}</a>}
              end
      end
      if max != page_count
        li << %{<span class="ellipsis"/>} << %{<a href="#{escape_html build_path(path, options.merge(page: page_count))}">#{page_count}</a>}
      end
      if page_nr < page_count
        li << %{<span class="ellipsis"/>} if unlimited
        li << %{<a href="#{escape_html build_path(path, options.merge(page: page_nr + 1))}">&#9656;</a>}
      else
        li << %{<span class="disabled">&#9656;</span>}
      end
      ('<ul class="pagination">' + li.map {|x| "<li>#{x}</li>"}.join + '</ul>').html_safe
    end

    def date(t)
      %{<span class="date" data-epoch="#{t.to_i}">#{t.strftime('%d %h %Y %H:%M')}</span>}.html_safe
    end

    def format_diff(diff)
      summary   = PatchSummary.new(links: true)
      formatter = PatchFormatter.new(links: true, header: true)
      PatchParser.parse(diff.patch, summary, formatter)
      (summary.html + formatter.html).html_safe
    end

    def breadcrumbs(page)
      path = page.try(:path) || ''
      li = [%{<li>
<a accesskey="z" href="#{escape_html build_path(nil, version: page)}">#{escape_html :root.t}</a></li>}]
      path.split('/').inject('') do |parent,elem|
        current = parent/elem
        li << %{<li>
<a href="#{escape_html build_path(current, version: page)}">#{escape_html elem}</a></li>}
        current
      end
      ('<ul class="breadcrumbs">' << li.join('<li>/</li>') << '</ul>').html_safe
    end

    def build_path(page, options = {})
      options = options.dup
      action = options.delete(:action)
      version = options.delete(:version)
      path = (page.try(:path) || page).to_s

      if action
        raise ArgumentError if version
        path = action.to_s/path
      else
        version ||= page if Page === page
        version = version.tree_version if Page === version
        path = 'version'/version/path if version && (options.delete(:force_version) || !version.head?)
      end

      unless options.empty?
        query = build_query(options)
        path += '?' + query unless query.empty?
      end
      '/' + (Config['base_path'] / path)
    end
  end

  module HttpHelper
    include Util

    # Cache control for page
    def cache_control(options)
      return if !Config['production']

      if options[:no_cache]
        response.headers.delete('ETag')
        response.headers.delete('Last-Modified')
        response.headers.delete('Cache-Control')
        return
      end

      last_modified = options.delete(:last_modified)
      modified_since = env['HTTP_IF_MODIFIED_SINCE']
      last_modified = last_modified.try(:to_time) || last_modified
      last_modified = last_modified.try(:httpdate) || last_modified

      if options[:version]
        options[:etag] = options[:version].cache_id
        options[:last_modified] = options[:version].date
      end

      if User.logged_in?
        # Always private mode if user is logged in
        options[:private] = true

        # Special etag for authenticated user
        options[:etag] = "#{User.current.name}-#{options[:etag]}" if options[:etag]
      end

      if options[:etag]
        value = '"%s"' % options.delete(:etag)
        response['ETag'] = value.to_s
        response['Last-Modified'] = last_modified if last_modified
        if etags = env['HTTP_IF_NONE_MATCH']
          etags = etags.split(/\s*,\s*/)
          # Etag is matching and modification date matches (HTTP Spec §14.26)
          halt :not_modified if (etags.include?(value) || etags.include?('*')) && (!last_modified || last_modified == modified_since)
        end
      elsif last_modified
        # If-Modified-Since is only processed if no etag supplied.
        # If the etag match failed the If-Modified-Since has to be ignored (HTTP Spec §14.26)
        response['Last-Modified'] = last_modified
        halt :not_modified if last_modified == modified_since
      end

      options[:public] = !options[:private]
      options[:max_age] ||= 0
      options[:must_revalidate] ||= true if !options.include?(:must_revalidate)

      response['Cache-Control'] = options.map do |k, v|
        if v == true
          k.to_s.tr('_', '-')
        elsif v
          v = 31536000 if v.to_s == 'static'
          "#{k.to_s.tr('_', '-')}=#{v}"
        end
      end.compact.join(', ')
    end
  end

  module ApplicationHelper
    include BlockHelper
    include FlashHelper
    include PageHelper
    include HttpHelper
    include Templates

    def tabs(*actions)
      tabs = actions.map do |action|
        %{<li id="tabhead-#{action}"#{action?(action) ? ' class="selected"' : ''}><a href="#tab-#{action}">#{escape_html action.t}</a></li>}
      end
      %{<ul class="tabs">#{tabs.join}</ul>}.html_safe
    end

    def action?(action)
      if params[:action]
        params[:action].split('-', 2).first == action.to_s
      else
        unescape(request.path_info).starts_with?("/#{action}")
      end
    end

    def footer(content = nil, &block)
      include_or_define_block(:footer, content, &block)
    end

    def title(content = nil, &block)
      include_or_define_block(:title,  content, &block)
    end

    def head
      @@theme_link ||=
        begin
          file = File.join(Config['themes_path'], Config['theme'], 'style.css')
          path = build_path "static/themes/#{Config['theme']}/style.css?#{File.mtime(file).to_i}"
          %{<link rel="stylesheet" href="#{escape_html path}" type="text/css"/>}
        end
      @@script_link ||=
        begin
          path = build_path "static/script.js?#{File.mtime(File.join(Config['app_path'], 'static', 'script.js')).to_i}"
          %{<script src="#{escape_html path}" type="text/javascript"/>}
        end
      base_path = if page && page.root?
        url = request.base_url
        url << '/' << 'version'/page.tree_version if !page.head?
        %{<base href="#{escape_html url}/"/>}.html_safe
      end
      [base_path, @@theme_link, @@script_link, *invoke_hook(:head)].join.html_safe
    end

    def session
      env['rack.session'] ||= {}
    end

    def menu(name)
      menu = Menu.new(name)
      invoke_hook :menu, menu
      menu.to_html
    end

    alias render_partial render

    def render(name, options = {})
      layout = options.delete(:layout) != false && !params[:no_layout]
      output = Symbol === name ? render_partial(name, options) : name
      output = render_partial(:layout, options) { output } if layout
      invoke_hook :render, name, output, layout
      output
    end
  end
end
