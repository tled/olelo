description 'System information'

class Olelo::Application
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
@@ system.haml
- title 'System Information'
%h1 System Information
%ul.tabs
  %li#tabhead-runtime
    %a(href="#tab-runtime") Runtime
  %li#tabhead-configuration
    %a(href="#tab-configuration") Configuration
  %li#tabhead-plugins
    %a(href="#tab-plugins") Plugins
  - if Olelo.const_defined? 'Engine'
    %li#tabhead-engines
      %a(href="#tab-engines") Engines
  - if Olelo.const_defined? 'Filter'
    %li#tabhead-filters
      %a(href="#tab-filters") Filters
  - if Olelo.const_defined? 'Tag'
    %li#tabhead-tags
      %a(href="#tab-tags") Markup tags
#tab-runtime.tab
  %h2 Runtime
  %table.zebra
    %tr
      %td Ruby version:
      %td= RUBY_VERSION
    %tr
      %td Memory usage:
      %td #{@memory} MiB
    - if Olelo.const_defined? 'Worker'
      %tr
        %td Worker jobs
        %td= Olelo::Worker.jobs
#tab-configuration.tab
  %h2 Configuration
  %table.zebra
    %tr
      %td Production mode:
      %td= Olelo::Config.production?
    %tr
      %td Repository backend:
      %td= Olelo::Config.repository.type
    %tr
      %td Authentication backend:
      %td= Olelo::Config.authentication.service
    %tr
      %td Locale:
      %td= Olelo::Config.locale
    %tr
      %td Base path:
      %td= Olelo::Config.base_path
    %tr
      %td Log level:
      %td= Olelo::Config.log.level
    %tr
      %td Sidebar page:
      %td
        %a{:href => absolute_path(Olelo::Config.sidebar_page)}= Olelo::Config.sidebar_page
    %tr
      %td Mime type detection order:
      %td= Olelo::Config.mime.join(', ')
#tab-plugins.tab
  %h2 Plugins
  %p These plugins are currently available on your installation.
  %table.zebra.full
    %thead
      %tr
        %th Name
        %th Description
        %th Dependencies
    %tbody
      - Olelo::Plugin.plugins.sort_by(&:name).each do |plugin|
        %tr
          %td= plugin.name
          %td= plugin.description
          %td= plugin.dependencies.join(', ')
      - Olelo::Plugin.disabled.sort.each do |plugin|
        %tr
          %td #{plugin} (disabled)
          %td unknown
          %td unknown
      - Olelo::Plugin.failed.sort.each do |plugin|
        %tr
          %td #{plugin} (failed)
          %td unknown
          %td unknown
- if Olelo.const_defined? 'Engine'
  #tab-engines.tab
    %h2 Engines
    %p
      \Every page is rendered by an appropriate rendering engine. The engine is selected automatically,
      \where engines with lower priority are preferred. An alternative output engine
      \can be selected using the view menu or manually using the "output" query parameter.
    .scrollable
      %table.zebra.full
        %thead
          %tr
            %th Name
            %th Description
            %th Output Mime Type
            %th Accepted mime types
            %th Hidden
            %th Cacheable
            %th Layout
            %th Priority
            %th Provided by plugin
        %tbody
          - Olelo::Engine.engines.values.flatten.each do |engine|
            %tr
              %td= engine.name
              %td= engine.description
              %td= engine.mime
              %td= engine.accepts
              %td!= check_mark engine.hidden?
              %td!= check_mark engine.cacheable?
              %td!= check_mark engine.layout?
              %td= engine.priority
              %td= engine.plugin.name
- if Olelo.const_defined? 'Filter'
  #tab-filters.tab
    %h2 Filters used by filter engines
    %p Filters can be chained to build filter engines.
    %table.zebra.full
      %thead
        %tr
          %th Name
          %th Description
          %th Subfilters
          %th Provided by plugin
      %tbody
        - Olelo::Filter.registry.each do |name, filter|
          %tr
            %td= name
            %td= filter.description
            %td!= check_mark filter.respond_to?(:subfilter)
            %td= filter.plugin.try(:name)
    %h2 Filter engine definitions
    %table.zebra.full
      %thead
        %tr
          %th Name
          %th Filters
      %tbody
      - Olelo::Engine.engines.values.flatten.select {|engine| Olelo::FilterEngine === engine }.each do |engine|
        %tr
          %td= engine.name
          %td= engine.definition
- if Olelo.const_defined? 'Tag'
  #tab-tags.tab
    %h2 Markup tags
    %p
      Markup tags can be included in the wikitext like normal html tags. These tags are provided by plugins as wikitext extensions.
      The namespace prefixes are optional and can be used in case of ambiguities.
    %table.zebra.full
      %thead
        %tr
          %th Name
          %th Description
          %th Provided by plugin
          %th Required attributes
      %tbody
        - Olelo::Tag.tags.values.uniq.sort_by(&:full_name).each do |tag|
          %tr
            %td= tag.full_name
            %td= tag.description
            %td= tag.plugin.name
            %td= tag.requires.join(', ')
