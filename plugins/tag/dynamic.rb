description  'Support for dynamic tags'
dependencies 'filter/tag'

# Extend the define method to support dynamic tags
class << Olelo::Tag
  alias original_define define
  def define(name, options = {}, &block)
    options[:plugin] ||= Plugin.current(1) || Plugin.current
    if options.delete(:dynamic)
      Application.class_eval { define_method("DYNTAG #{name}", &block) }
      original_define(name, options) do |context, attrs, content|
        data = [name, attrs, content]
        %{<div class="dyntag">#{encode64 Marshal.dump(data)}</div>}
      end
    else
      original_define(name, options, &block)
    end
  end
end

# Evaluate dynamic tags
Application.hook :layout do |name, doc|
  tags = doc.css('.dyntag')
  cache_control(:no_cache => true) if !tags.empty?
  tags.each do |element|
    content = begin
      data = Marshal.load(decode64(element.content))
      send("DYNTAG #{data[0]}", data[1], data[2]).to_s
    rescue Exception => ex
      Plugin.current.logger.error ex
      escape_html ex.message
    end
    element.replace(content)
  end
end

# Dynamic test tag
Tag.define :fortune, :dynamic => true do |attrs, content|
  text = `fortune`
  escape_html(text) if valid_xml_chars?(text)
end
