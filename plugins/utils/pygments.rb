description    'Pygments syntax highlighter'
dependencies   'utils/assets', 'utils/shell'
export_scripts 'pygments.css'

module Olelo::Pygments
  include Util

  FORMAT_OPTIONS = %w(-O encoding=utf8 -O linenos=table -O cssclass=pygments -f html -l)
  @patterns = {}
  @formats = []

  def self.pygmentize(text, format)
    return pre(text) if !@formats.include?(format)
    options = FORMAT_OPTIONS + [format]
    content = Shell.pygmentize(*options).run(text)
    content.blank? ? pre(text) : content
  end

  def self.file_format(name)
    pattern = @patterns.keys.find {|p| File.fnmatch(p, name)}
    pattern && @patterns[pattern]
  end

  def self.pre(text)
    "<pre>#{escape_html(text.strip)}</pre>"
  end

  def self.setup
    format = ''
    output = `pygmentize -L lexer`
    output.split("\n").each do |line|
      if line =~ /^\* ([^:]+):$/
        format = $1.split(', ')
        @formats += format
      elsif line =~ /^   [^(]+ \(filenames ([^)]+)/
        $1.split(', ').each {|s| @patterns[s] = format.first }
      end
    end
  end

  private_class_method :pre
end

def setup
  Pygments.setup
end
