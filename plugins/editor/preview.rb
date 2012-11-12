# -*- coding: utf-8 -*-
description  'Enhance editor form with preview and diff'
dependencies 'aspects'

class ::Olelo::Application
  before :edit_buttons, 1000 do
    %{<button data-target="enhanced-edit" type="submit" name="action" value="preview" accesskey="p">#{:preview.t}</button>
      <button data-target="enhanced-edit" type="submit" name="action" value="changes" accesskey="c">#{:changes.t}</button>}
  end

  after :edit_buttons do
    %{<div id="enhanced-edit">#{flash[:preview] || flash[:changes]}</div>}
  end

  def post_preview
    raise 'No content' if !params[:content]
    params[:content].gsub!("\r\n", "\n")

    if page.new? || !params[:pos]
      # Whole page edited, assign new content before aspect search
      page.content = params[:content]
      aspect = Aspects::Aspect.find(page, layout: true)
    else
      # We assume that aspect stays the same if section is edited
      aspect = Aspects::Aspect.find(page, layout: true)
      page.content = params[:content]
    end
    context = Aspects::Context.new(page: page, request: request, private: {preview: true})
    preview = aspect && aspect.call(context, page)
    flash.now[:preview] = preview ? %{<hr/>#{preview}} : nil
    halt render(request.xhr? ? flash.now[:preview] : :edit)
  end

  def post_changes
    raise 'No content' if !params[:content]
    params[:content].gsub!("\r\n", "\n")

    original = Tempfile.new('original')
    original.write(params[:pos] ? page.content[params[:pos].to_i, params[:len].to_i] : page.content)
    original.close

    new = Tempfile.new('new')
    new.write(params[:content].to_s)
    new.close

    # Read in binary mode and fix encoding afterwards
    patch = IO.popen("diff -u '#{original.path}' '#{new.path}'", 'rb') {|io| io.read }
    patch.force_encoding(Encoding.default_external)
    changes = PatchParser.parse(patch, PatchFormatter.new).html
    flash.now[:changes] = changes.blank? ? %{<div class="flash">#{:no_changes.t}</div>} : changes
    halt render(request.xhr? ? flash.now[:changes] : :edit)
  end
end

__END__
@@ locale.yml
cs_CZ:
  changes: 'Změny'
  preview: 'Náhled'
de:
  changes: 'Änderungen'
  preview: Vorschau
en:
  changes: Changes
  preview: Preview
fr:
  changes: "Changement"
  preview: "Prévisualisez"
