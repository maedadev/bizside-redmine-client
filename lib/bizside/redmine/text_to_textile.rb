class Bizside::Redmine::TextToTextile

  # NOTE:  refs #16729 special symbol for xml
  def self.convert(text)
    text.gsub!('<', '&lt;')
    text.gsub!('>', '&gt;')
    text.gsub!('&', '&amp;')
    text
  end

end
