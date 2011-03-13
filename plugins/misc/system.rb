description 'System information'

class ::Olelo::Application
  get '/system' do
    GC.start
    @memory = `ps -o rss= -p #{$$}`.to_i / 1024
    render :system
  end

  def check_mark(value)
    value ? '&#x2713;' : ''
  end
end

__END__
@@ system.slim
- title 'System Information'
h1 System Information
ul.tabs
  li#tabhead-runtime
    a href="#tab-runtime" Runtime
  li#tabhead-configuration
    a href="#tab-configuration" Configuration
  li#tabhead-plugins
    a href="#tab-plugins" Plugins
  - if defined?(Olelo::Plugin::Aspects::Aspect)
    li#tabhead-aspects
      a href="#tab-aspects" Aspects
  - if defined?(Olelo::Plugin::Filters::Filter)
    li#tabhead-filters
      a href="#tab-filters" Filters
  - if defined?(Olelo::Plugin::Tags::Tag)
    li#tabhead-tags
      a href="#tab-tags" Tags
#tab-runtime.tab
  h2 Runtime
  table
    tr
      td Ruby version:
      td= RUBY_VERSION
    tr
      td Memory usage:
      td #{@memory} MiB
    - if defined?(Olelo::Worker)
      tr
        td Worker jobs
        td= Olelo::Worker.jobs
#tab-configuration.tab
  h2 Configuration
  table
    tr
      td Production mode:
      td= Olelo::Config['production']
    tr
      td Repository backend:
      td= Olelo::Config['repository.type']
    tr
      td Authentication backend:
      td= Olelo::Config['authentication.service']
    tr
      td Locale:
      td= Olelo::Config['locale']
    tr
      td Base path:
      td= Olelo::Config['base_path']
    tr
      td Log level:
      td= Olelo::Config['log.level']
    tr
      td Sidebar page:
      td
        a href=build_path(Olelo::Config['sidebar_page']) = Olelo::Config['sidebar_page']
    tr
      td Mime type detection order:
      td= Olelo::Config['mime'].join(', ')
#tab-plugins.tab
  h2 Plugins
  p These plugins are currently available on your installation.
  table.full
    thead
      tr
        th Name
        th Description
        th Dependencies
    tbody
      - Olelo::Plugin.loaded.sort_by(&:path).each do |plugin|
        tr
          td= plugin.path
          td= plugin.description
          td= plugin.dependencies.to_a.join(', ')
      - Olelo::Plugin.disabled.sort.each do |plugin|
        tr
          td #{plugin} (disabled)
          td unknown
          td unknown
      - Olelo::Plugin.failed.sort.each do |plugin|
        tr
          td #{plugin} (failed)
          td unknown
          td unknown
- if defined?(Olelo::Plugin::Aspects::Aspect)
  #tab-aspects.tab
    h2 Aspects
    p
      | Every page is rendered by an aspect. The default aspect is selected automatically,
        where aspects with lower priority are preferred. An alternative aspect
        can be selected using the view menu or manually using the "aspect" query parameter.
    .scrollable
      table.full
        thead
          tr
            th Name
            th Description
            th Output Mime Type
            th Accepted mime types
            th Hidden
            th Cacheable
            th Layout
            th Priority
            th Provided by plugin
        tbody
          - Olelo::Plugin::Aspects::Aspect.aspects.values.flatten.sort_by(&:name).each do |aspect|
            tr
              td= aspect.name
              td= aspect.description
              td= aspect.mime
              td= aspect.accepts ? aspect.accepts.inspect : '*'
              td== check_mark aspect.hidden?
              td== check_mark aspect.cacheable?
              td== check_mark aspect.layout?
              td= aspect.priority
              td= aspect.plugin.path
- if defined?(Olelo::Plugin::Filters::Filter)
  #tab-filters.tab
    h2 Filters used by filter aspects
    p Filters can be chained to build filter aspects.
    table.full
      thead
        tr
          th Name
          th Description
          th Subfilters
          th Provided by plugin
      tbody
        - Olelo::Plugin::Filters::Filter.registry.values.sort_by(&:name).each do |filter|
          tr
            td= filter.name
            td= filter.description
            td== check_mark filter.respond_to?(:subfilter)
            td= filter.plugin.path
    h2 Filter aspect definitions
    table.full
      thead
        tr
          th Name
          th Filters
      tbody
      - Olelo::Plugin::Aspects::Aspect.aspects.values.flatten.select {|aspect| Olelo::Plugin::Filters::FilterAspect === aspect }.sort_by(&:name).each do |aspect|
        tr
          td= aspect.name
          td= aspect.definition
- if defined?(Olelo::Plugin::Tags::Tag)
  #tab-tags.tab
    h2 Tags
    p
      | Tags can be included in the wikitext like normal html tags. These tags are provided by plugins as wikitext extensions.
        The namespace prefixes are optional and can be used in case of ambiguities.
    table.full
      thead
        tr
          th Name
          th Description
          th Immediate
          th Dynamic
          th Autoclose
          th Provided by plugin
          th Optional attributes
          th Required attributes
      tbody
        - Olelo::Plugin::Tags::Tag.tags.values.uniq.sort_by(&:full_name).each do |tag|
          tr
            td= tag.full_name
            td= tag.description
            td== check_mark tag.immediate
            td== check_mark tag.dynamic
            td== check_mark tag.autoclose
            td= tag.plugin.path
            td= tag.optional.to_a.join(', ')
            td= tag.requires.to_a.join(', ')
