description  'Enhanced edit form with preview and diff'
dependencies 'aspect/aspect'

class Olelo::Application
  hook :dom do |name, doc, layout|
    if name == :edit
      if flash[:preview]
        doc.css('#content .tabs').before %{<div class="preview">#{flash[:preview]}</div>}
      elsif flash[:changes]
        doc.css('#content .tabs').before flash[:changes]
      end

      doc.css('#tab-edit button[type=submit]').before(
        %{<button type="submit" name="action" value="preview" accesskey="p">#{:preview.t}</button>
          <button type="submit" name="action" value="changes" accesskey="c">#{:changes.t}</button>}.unindent)
    end
  end

  def post_preview
    raise 'No content' if !params[:content]
    params[:content].gsub!("\r\n", "\n")

    if page.new? || !params[:pos]
      # Whole page edited, assign new content before aspect search
      page.content = params[:content]
      aspect = Aspect.find(page, :layout => true)
    else
      # We assume that aspect stays the same if section is edited
      aspect = Aspect.find(page, :layout => true)
      page.content = params[:content]
    end
    flash.now[:preview] = aspect && aspect.call(Context.new(:page => page, :request => request), page)
    halt render(:edit)
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
    patch.force_encoding(Encoding::UTF_8) if patch.respond_to? :force_encoding
    flash.now[:changes] = PatchParser.parse(patch, PatchFormatter.new).html

    halt render(:edit)
  end
end
