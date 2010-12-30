description 'Page information aspect'

Aspect.create(:pageinfo, :priority => 4, :layout => true, :cacheable => true) do
  def call(context, page)
    @page = page
    render :info
  end
end

__END__
@@ info.slim
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
    - if @page.version
      tr
        td= :last_modified.t
        td= date @page.version.date
      tr
        td= :version.t
        td.version = @page.version
    tr
      td= :type.t
      td= @page.mime.comment.blank? ? @page.mime : "#{@page.mime.comment} (#{@page.mime})"
    - if !@page.content.empty?
      tr
        td= :download.t
        td
          a href=page_path(@page, :aspect => 'download') = :download.t
