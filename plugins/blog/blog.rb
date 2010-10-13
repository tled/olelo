description    'Blog engine'
dependencies   'filter/tag', 'utils/assets'
export_scripts '*.css'

Page.attributes do
  list(:tags)
end

Application.get '(/:path)/:year(/:month)', :year => '20\d{2}', :month => '(?:0[1-9])|(?:1[1-2])' do
  params[:output] = 'blog'
  send('GET /')
end

Tag.define 'menu', :optional => :path, :description => 'Show blog menu', :dynamic => true do |context, attrs, content|
  page = Page.find(attrs[:path]) rescue nil
  if page
    Cache.cache("blog-#{page.path}-#{page.version.cache_id}", :update => context.request.no_cache?, :defer => true) do
      years = {}
      page.children.each do |child|
        (years[child.version.date.year] ||= [])[child.version.date.month] = true
      end
      render :menu, :locals => {:years => years, :page => page}
    end
  end
end

Engine.create(:blog, :priority => 3, :layout => true, :cacheable => true, :hidden => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    @page = context.page

    articles = @page.children.sort_by {|child| -child.version.date.to_i }

    year = context.params[:year].to_i
    articles.reject! {|article| article.version.date.year != year } if year != 0
    month = context.params[:month].to_i
    articles.reject! {|article| article.version.date.month != month } if month != 0

    @page_nr = [context.params[:page].to_i, 1].max
    per_page = 10
    @page_count = articles.size / per_page + 1
    articles = articles[((@page_nr - 1) * per_page) ... (@page_nr * per_page)].to_a

    @articles = articles.map do |page|
      begin
        content = Engine.find!(page, :layout => true).output(context.subcontext(:page => page, :params => {:included => true}))
        if !context.params[:full]
          paragraphs = XMLFragment(content).xpath('p')
          content = ''
          paragraphs.each do |p|
            content += p.to_xhtml
            break if content.length > 10000
          end
        end
      rescue Engine::NotAvailable => ex
        %{<span class="error">#{escape_html ex.message}</span>}
      end
      [page, content]
    end
    render :blog, :locals => {:full => context.params[:full]}
  end
end

__END__
@@ blog.haml
.blog
  - @articles.each do |page, content|
    .article
      %h2
        %a.name{:href => absolute_path(page) }= page.name
      .date!= date page.version.date
      .author= :written_by.t(:author => page.version.author.name)
      - tags = page.attributes['tags'].to_a
      - if !tags.empty?
        %ul.tags
          != list_of(tags) do |tag|
            = tag
      .content!= content
      - if !full
        %a.full{:href => absolute_path(page.path) }= :full_article.t
!= pagination(page_path(@page), @page_count, @page_nr, :output => 'blog')
@@ menu.haml
%table.blog-menu
  - years.keys.sort.each do |year|
    %tr
      %td
        %a{:href => absolute_path(page.path/year) }= year
      %td
        - (1..12).select {|m| years[year][m] }.each do |month|
          - m = '%02d' % month
          %a{:href => absolute_path(page.path/year/m) }= m
