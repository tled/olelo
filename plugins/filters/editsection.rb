description 'Adds links for section editing for headlines'

Page.attributes do
  boolean :no_editsection
end

class EditSection < Filters::NestingFilter
  def find_sections_regexp(content, regexp)
    sections, offset = [], 0
    while (offset = content.index(regexp, offset))
      sections.last[1] = offset if sections.last
      # [Section start, section end, Position to insert edit link, section text]
      sections << [offset + $2.size, content.length, offset + $1.size, $3.strip]
      offset += $&.size
    end
    sections
  end

  # Creole/Mediawiki style headlines (e.g. == Headline ==)
  def find_sections_creole(content)
    find_sections_regexp(content, /((\A|\s*\n)=+(.*?))=*\s*$/)
  end

  # ATX/Markdown style headlines (e.g. ## Headline)
  def find_sections_atx(content)
    find_sections_regexp(content, /((\A|\s*\n)#+(.*))$/)
  end

  # Returns section array
  # [[Section start, section end, Position to insert edit link, section text], ...]
  def find_sections(mime, content)
    case mime.to_s
    when %r{^text/x-(creole|mediawiki)$}
      find_sections_creole(content)
    when %r{^text/x-markdown}
      find_sections_atx(content)
    else
      raise "Mime type #{mime} not supported by editsection filter"
    end
  end

  def filter(context, content)
    page = context.page
    if context[:preview] || !page.head? || page.attributes['no_editsection']
      subfilter(context, content)
    else
      sections = find_sections(context.page.mime, content)
      offset = 0
      prefix = "EDIT#{object_id}X"
      sections.each_with_index do |h,i|
        link = " #{prefix}#{i} "
        content.insert(h[2] + offset, link)
        offset += link.size
      end
      content = subfilter(context, content)
      content.gsub!(/#{prefix}(\d+)/) do
        i = $1.to_i
        len = sections[i][1] - sections[i][0]
        path = build_path(page, action: :edit, pos: sections[i][0], len: len, comment: :section_edited.t(section: sections[i][3]))
        %{<a class="editsection" href="#{escape_html path}" title="#{escape_html :edit_section.t(section: sections[i][3])}">#{escape_html :edit.t}</a>}
      end
      content
    end
  end
end

Filters::Filter.register :editsection, EditSection

__END__
@@ locale.yml
cs_CZ:
  attribute_no_editsection: 'Zablokovat editaci sekcí'
  edit_section: 'Edituj sekci "%{section}"'
  section_edited: 'Sekce "%{section}" editována'
de:
  attribute_no_editsection: 'Bearbeiten von Bereichen deaktivieren'
  edit_section: 'Bearbeite Bereich "%{section}"'
  section_edited: 'Bereich "%{section}" bearbeitet'
en:
  attribute_no_editsection: 'Disable Section Editing'
  edit_section: 'Edit section "%{section}"'
  section_edited: 'Section "%{section}" edited'
fr:
  attribute_no_editsection: "Désactiver l'édition"
  edit_section: "Éditer la section \"%{section}\""
  section_edited: "Section \"%{section}\" éditée"
