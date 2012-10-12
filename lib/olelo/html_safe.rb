class Object
  def html_safe?
    false
  end
end

class String
  class HtmlString < String
    def html_safe?
      true
    end

    def html_safe
      self
    end

    def to_s
      self
    end
  end

  def html_safe?
    false
  end

  def html_safe
    HtmlString.new(self)
  end
end
