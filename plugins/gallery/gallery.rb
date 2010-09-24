description    'Gallery engine'
dependencies   'engine/engine', 'utils/assets'
export_scripts '*.css'

Engine.create(:gallery, :priority => 3, :layout => true, :hidden => true, :cacheable => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    @per_row = 4
    per_page = @per_row * 4
    @page_nr = context.params[:page].to_i
    @page = context.page
    @images = @page.children.select {|page| page.mime.image? }
    @last_page = @images.size / per_page
    @images = @images[(@page_nr * per_page) ... ((@page_nr + 1) * per_page)].to_a
    render :gallery
  end
end

__END__
@@ gallery.haml
!= pagination(page_path(@page), @last_page, @page_nr, :output => 'gallery')
%table.gallery
  - @images.each_slice(@per_row) do |row|
    %tr
      - row.each do |image|
        :ruby
          thumb_path = page_path(image, :output => 'image', :geometry => '150x150>')
          info_path  = page_path(image)
          description = image.attributes['description'] ||
                        image.attributes['title'] ||
                        image.name.gsub(/([^\s])[_\-]/, '\1 ')
        %td
          %a.fancybox(href=info_path rel="gallery" title="#{description}")
            %img(src=thumb_path alt='')
          %a.title(href=info_path)= description
