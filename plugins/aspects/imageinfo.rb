description 'Image information aspect'
dependencies 'utils/image_magick'

Aspect.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true, :accepts => %r{^image/}) do
  def call(context, page)
    @page = page
    identify = ImageMagick.identify('-format', "%m\n%h\n%w\n%[EXIF:*]", '-').run(page.content).split("\n")
    @type = identify[0]
    @geometry = "#{identify[1]}x#{identify[2]}"
    @exif = identify[3..-1].to_a.map {|line| line.sub(/^exif:/, '').split('=', 2) }
    render :info
  end
end

__END__
@@ info.slim
p
  a href=build_path(@page, :aspect => 'image')
    img src=build_path(@page, :aspect => 'image', :geometry => '640x480>') alt=@page.title
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
- unless @exif.empty?
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
