description 'Image information engine'
dependencies 'utils/imagemagick'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true, :accepts => 'image/') do
  def output(context)
    @page = context.page
    identify = ImageMagick.identify('-format', '%m %h %w', '-').run(context.page.content).split(' ')
    @type = identify[0]
    @geometry = "#{identify[1]}x#{identify[2]}"
    @exif = Shell.exif('-m', '/dev/stdin').run(context.page.content)
    @exif.force_encoding(Encoding::UTF_8) if @exif.respond_to? :force_encoding
    @exif = @exif.split("\n").map {|line| line.split("\t") }
    @exif = nil if !@exif[0] || !@exif[0][1]
    render :info
  end
end

__END__
@@ info.slim
p
  a{:href => page_path(@page, :output => 'image') }
    img{:src=> page_path(@page, :output => 'image', :geometry => '640x480>'), :alt => @page.title}
h3= :information.t
table
  tbody
    tr
      td= :name.t
      td= @page.name
    tr
      td= :title.t
      td= @page.title
    tr
      td= :description.t
      td= @page.attributes['description']
    tr
      td= :type.t
      td= @type
    tr
      td= :geometry.t
      td= @geometry
    - if @page.version
      tr
        td= :last_modified.t
        td= date @page.version.date
      tr
        td= :version.t
        td.version= @page.version
- if @exif
  h3= :exif.t
  table
    thead
      tr
        th= :entry.t
        th= :value.t
    tbody
      - @exif.each do |key, value|
        tr
          td= key
          td= value
