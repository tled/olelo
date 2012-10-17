description    'Tree Viewer'
dependencies   'aspects', 'utils/assets', 'misc/variables'
export_scripts '*.js', '*.css'
export_assets  'images/*'

Aspects::Aspect.create('treeview.json', :hidden => true, :cacheable => true, :mime => 'application/json; charset=utf-8') do
  def call(context, page)
    # Format [[has-children, classes, path, name], ...]
    # Example: [[0, 'file-type-pdf', '/a/b.pdf', 'b.pdf'], ...]
    page.children.map do |child|
      classes = child.children.empty? ? 'page' : 'folder'
      classes << " file-type-#{child.extension.downcase}" if !child.extension.empty?
      [child.children.empty? ? 0 : 1, classes, build_path(child), child.name]
    end.to_json
  end
end
