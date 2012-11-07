description 'Markdown nowiki filter'

# Embeds indented markdown text blocks in <notags> tags
# and adds <notags> around ``texts``
Filter.create :markdown_nowiki do |context, content|
  output = ''
  block, state = nil, nil
  content.each_line do |line|
    if block
      if line =~ /\A( {4}|\t)/
        block << line
        state = :in
      elsif line =~ /\A\s*\Z/
        block << line
        state = :after if state == :in
      elsif state == :after
        output << "<notags>#{block}</notags>"
        block = nil
      else
        block << line
        line = block
        block = nil
      end
    elsif line =~ /\A\s*\Z/
      block, state = line, :before
    end

    unless block
      output << line.gsub(/``.*?``|`[^`]*`/, '<notags>\0</notags>')
    end
  end
  output << (state == :before ? block : "<notags>#{block}</notags>") if block
  output
end
