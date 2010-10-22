description  'Subpages engine'
dependencies 'engine/engine'

Engine.create(:subpages, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    @page_nr = [context.params[:page].to_i, 1].max
    per_page = 20
    @page = context.page
    @page_count = @page.children.size / per_page + 1
    @children = @page.children[((@page_nr - 1) * per_page) ... (@page_nr * per_page)].to_a
    render :subpages
  end
end

__END__
@@ subpages.slim
= pagination(page_path(@page), @page_count, @page_nr, :output => 'subpages')
table#subpages-table
  thead
    tr
      th= :name.t
      th= :description.t
      th= :last_modified.t
      th= :author.t
      th= :comment.t
      th= :actions.t
  tbody
    - @children.each do |child|
      - classes = child.children.empty? ? 'page' : 'folder'
      - if !child.extension.empty?
        - classes << " file-type-#{child.extension}"
      tr
        td.link
          a href=page_path(child) class=classes = child.name
        td= truncate(child.attributes['description'], 30)
        td= date(child.version.date)
        td= truncate(child.version.author.name, 30)
        td= truncate(child.version.comment, 30)
        td.actions
          a.action-edit href=action_path(child, :edit) title=:edit.t = :edit.t
          a.action-history href=action_path(child, :history) title=:history.t = :history.t
          a.action-move href=action_path(child, :move) title=:move.t = :move.t
          a.action-delete href=action_path(child, :delete) title=:delete.t = :delete.t
= pagination(page_path(@page), @page_count, @page_nr, :output => 'subpages')
