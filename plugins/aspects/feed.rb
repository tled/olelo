# -*- coding: utf-8 -*-
description 'Newsfeed Aspect'
require 'time'

Aspect.create(:feed, cacheable: true, hidden: true) do
  def call(context, page)
    format = context.params[:format]

    url = context.request.base_url
    context.header['Content-Type'] = "application/#{format == 'atom' ? 'atom' : 'rss'}+xml; charset=utf-8"

    per_page = 30
    page_nr = [context.params[:page].to_i, 1].max
    history = page.history((page_nr - 1) * per_page, per_page)

    feed = {
      self_link: url + build_path(page, {aspect: 'feed', format: format}.reject{ |k,v| v.blank? }),
      generator: 'Ōlelo',
      title: Config['title'],
      link: url + '/' + page.path,
      description: Config['title'] + ' Feed',
      date: Time.now,
      author: Config['title'],
      items: []
    }
    history.each do |version|
      feed[:items] << {
        title: version.comment,
        link: "#{url}/changes/#{version}",
        date: version.date,
        author: version.author.name
      }
    end

    render(format == 'atom' ? :feed_atom : :feed_rss, locals: {feed: feed})
  end
end

Application.hook :head do
  result = %{<link rel="alternate" type="application/atom+xml" title="Sitewide Atom Feed"
href="#{escape_html build_path('/', aspect: 'feed', format: 'atom')}"/>
<link rel="alternate" type="application/rss+xml" title="Sitewide RSS Feed"
href="#{escape_html build_path('/', aspect: 'feed', format: 'rss')}"/>}
  result << %{<link rel="alternate" type="application/atom+xml" title="#{escape_html page.path} Atom Feed"
href="#{escape_html(build_path(page.path, aspect: 'feed', format: 'atom'))}"/>
<link rel="alternate" type="application/rss+xml" title="#{escape_html page.path} RSS Feed"
href="#{escape_html(build_path(page.path, aspect: 'feed', format: 'rss'))}"/>} if page && !page.new? && !page.root?
  result
end

__END__
@@ feed_atom.slim
doctype xml
feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
  author
    name = feed[:title]
  generator = feed[:generator]
  id = feed[:link]
  link href=feed[:link] /
  link href=feed[:self_link] rel="self" type="application/atom+xml"/
  subtitle = feed[:description]
  title = feed[:title]
  updated = feed[:date].iso8601()
  - feed[:items].each do |item|
    entry
      id = item[:link]
      link href=item[:link] /
      title = item[:title]
      updated = item[:date].iso8601()
      dc:creator = item[:author]
      dc:date = item[:date].iso8601()
@@ feed_rss.slim
doctype xml
rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
  channel
    title = feed[:title]
    link = feed[:link]
    description = feed[:description]
    pubDate = feed[:date].rfc822()
    atom:link href=feed[:self_link] rel="self" type="application/rss+xml"/
    - feed[:items].each do |item|
      item
        title = item[:title]
        guid = item[:link]
        link = item[:link]
        pubDate = item[:date].rfc822()
        dc:creator = item[:author]
