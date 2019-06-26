# Refer to https://github.com/jystewart/html2textile
require 'cgi'
require 'nokogiri'

class Bizside::Redmine::HtmlToTextile
  NEWLINE = "\n"

  # SAX parser
  class Converter < Nokogiri::XML::SAX::Document
    # Tag translations

    # Maps tokens for opening and closing tags
    SHARED_TAGS = {
      # Text formatting
      :b => '**',
      :strong => '*',
    }.freeze

    # Maps tokens for opening tags
    OPENING_TAGS = SHARED_TAGS.dup.update(
      # Headings
      :table => 'h2. ',
      :h1 => "\n h1. ",
      :h2 => 'h2. ',

      # Tables
      :th => '|_.',
      :td => '|',

      # Special
      :a => '"',

      # Structures
      :p => 'p. ',
      :br => NEWLINE,
    ).freeze

    # Maps tokens for closing tags
    CLOSING_TAGS = SHARED_TAGS.dup.update(
      # Tables
      :tr => '|',
      :td => ' ',
      :th => ' ',

      # Special
      :a => '":',
    ).freeze

    # Typical block elements
    BLOCK = [:h1, :h2, :p, :div, :table].freeze

    # This is kinda a special case for block elements
    ROW = [:tr, :li].freeze

    # Note that th/td in Textile are sort of inline despite truly being block
    INLINE = [:b, :strong, :span, :a, :th, :td].freeze

    attr_reader :converted, :original, :stack

    def initialize
      @converted = ''
      @stack = []
    end

    # Opening tag callback
    def start_element(tag_name, attributes = [])
      # Preprocess, and push to stack
      element = tag_name.downcase.to_sym
      attribs = Hash[attributes]
      opening = OPENING_TAGS[element].to_s.dup
      styling = prepare_styles(attribs, element)
      spaces = spacing(element)
      stack << [element, attribs]

      # Styling info gets positioned depending on element type
      content = case
        when BLOCK.include?(element)
          opening.sub('.', styling + '.')
        when ROW.include?(element)
          (styling.empty?) ? opening + ' ' : opening + styling + ('.' if :td == element).to_s + ' '
        else opening + styling
      end

      # add white space & content
      append_white(spaces)
      converted << content
    end

    # Closing tag callback
    def end_element(tag_name)
      element, attribs = stack.pop
      spaces = spacing(element)
      closing = CLOSING_TAGS[element].to_s

      # Deal with cases for a/img
      converted << case element
        when :a
          special_ending(attribs['title']) + closing + attribs['href'].to_s
        else closing
      end
      append_white(spaces)
    end

    # Normal character stream
    def characters(text)
      # # Newlines should not be treated like <br /> tags, however don't indent
      # on new lines so consume any preceeding whitespace
      content = CGI.unescapeHTML(text).gsub(NEWLINE, ' ')
      content.rstrip! if content.ends_with? NEWLINE
      content.lstrip! if converted.ends_with? NEWLINE
      converted << content
    end

    private

    # Put white space at the end, but only if required
    def append_white(spacing)
      (- spacing.size).upto(-1) do |i|
        space, last = spacing[i], converted[i]
        converted << space unless space == last or NEWLINE == last
      end
    end

    # Create styles, id, CSS classes, colspans, padding
    def prepare_styles(attribs, element)
      styling = attribs['class'].to_s.split(/\s+/)
      styling << '#' + attribs['id'] unless attribs['id'].blank?
      [].tap do |items|
        styles = attribs['style'].to_s.dup.strip
        unless styles.blank?
          items << '{%s}' % styles unless styles.blank?
        end
        items << '(%s)' % styling.join(' ') unless styling.empty?
      end.join
    end

    # For special case closing tags (a and img)
    def special_ending(text)
      (text.present?) ? '(%s)' % text : ''
    end

    # Get spacing gap for a tag
    def spacing(element)
      return NEWLINE * 2 if BLOCK.include? element
      return NEWLINE if ROW.include? element
      ''
    end
  end

  # Wrapper for SAX parser
  def self.convert(text)
    # Note, start-of-line is white space trimmed and we use HTML parsing to wrap up a fake HTML root node
    text.gsub!(/<title.*title>/, '')
    text.gsub!(/<style.*style>/m, '')
    text.gsub!(/class="rla-report-table" cellspacing="0"/, '')
    text.gsub!(/class="alt"/, '')
    mark_up = text.gsub(/\n\ +/, NEWLINE).gsub(/\>\s*\n/, '> ')
    converter = Converter.new
    Nokogiri::HTML::SAX::Parser.new(converter).parse(mark_up)
    converter.converted.strip
  end

  def self.tweak_wiki_style(textile_format)
    content = textile_format.gsub(/\n\n\s\|\n/, "\n")
    content.gsub!(/^h2\. Routing Errors$/, "h2. Routing Errors \n")
    content.gsub!(/^h2\. Parse warnings$/, "\n h2. Parse warnings \n")
    content.gsub!(/^h2\. Thanks for using request-log-analyzer$/, "--- \n\n h2. Thanks for using request-log-analyzer")
    content.gsub!(/\n\s\|_\./, "\n{background: #CAE8EA}. |_.")

    # Get threshold to draw color only Mean & StdDev
    threshold = ENV['THRESHOLD'] || 400
    colorized_content = ''
    content.each_line do |line|
      splited = line.split('|')

      if splited[4].present?
        mean = splited[4].strip
        if mean.match(/^\d+ms$/)
          if mean.to_i > threshold.to_i
            splited[4] = mean.strip.gsub(/^\d+ms$/, "%{color:red} #{mean}%")
          end
        elsif mean.match(/^\d+\.\d+s$/)
          if mean.to_f * 1000 > threshold.to_i
            splited[4] = mean.strip.gsub(/^\d+\.\d+s$/, "%{color:red} #{mean}%")
          end
        end
      end

      if splited[5].present?
        std_dev = splited[5].strip
        if std_dev.match(/^\d+ms$/)
          if std_dev.to_i > threshold.to_i
            splited[5] = std_dev.gsub(/^\d+ms$/, "%{color:red} #{std_dev}%")
          end
        elsif std_dev.match(/^\d+\.\d+s$/)
          if std_dev.to_f * 1000 > threshold.to_i
            splited[5] = std_dev.strip.gsub(/^\d+\.\d+s$/, "%{color:red} #{std_dev}%")
          end
        end
      end

       colorized_content << splited.join("|")
    end
    colorized_content
  end

end
