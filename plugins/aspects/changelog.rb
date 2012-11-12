# -*- coding: utf-8 -*-
description 'Changelog Aspect'
require 'rss/maker'

Aspect.create(:changelog, cacheable: true, hidden: true) do
  def call(context, page)
    format = context.params[:format]

    url = context.request.base_url
    context.header['Content-Type'] = "application/#{format == 'rss' ? 'rss' : 'atom'}+xml; charset=utf-8"

    per_page = 30
    page_nr = [context.params[:page].to_i, 1].max
    history = page.history((page_nr - 1) * per_page, per_page)

    content = RSS::Maker.make(format == 'rss' ? '2.0' : 'atom') do |feed|
      feed.channel.generator = 'Ōlelo'
      feed.channel.title = Config['title']
      feed.channel.id = feed.channel.link = url + '/' + page.path
      feed.channel.description = Config['title'] + ' Changelog'
      feed.channel.updated = Time.now
      feed.channel.author = Config['title']
      feed.items.do_sort = true
      history.each do |version|
        i = feed.items.new_item
        i.title = version.comment
        i.link = "#{url}/changes/#{version}"
        i.date = version.date
        i.dc_creator = version.author.name
      end
    end
    content.to_s
  end
end

Application.hook :head do
  result = %{<link rel="alternate" type="application/atom+xml" title="Sitewide Atom Changelog"
href="#{escape_html build_path('/', aspect: 'changelog', format: 'atom')}"/>
<link rel="alternate" type="application/rss+xml" title="Sitewide RSS Changelog"
href="#{escape_html build_path('/', aspect: 'changelog', format: 'rss')}"/>}
  result << %{<link rel="alternate" type="application/atom+xml" title="#{escape_html page.path} Atom Changelog"
href="#{escape_html(build_path(page.path, aspect: 'changelog', format: 'atom'))}"/>
<link rel="alternate" type="application/rss+xml" title="#{escape_html page.path} RSS Changelog"
href="#{escape_html(build_path(page.path, aspect: 'changelog', format: 'rss'))}"/>} if page && !page.new? && !page.root?
  result
end
