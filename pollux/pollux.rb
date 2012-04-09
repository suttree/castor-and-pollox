require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'

class Pollux
  def self.taller
    @config = YAML::load(File.open('/home/suttree/public_html/troisen.com/gemini/config/pollux.yml'))

    url = @config['urls'].sort_by{ rand }[0]
    feed = FeedNormalizer::FeedNormalizer.parse open(url)
    entry = feed.entries.sort_by{ rand }.first
    entry.clean!

    page = '/home/suttree/public_html/troisen.com/public/castor.html'
    doc = Nokogiri::HTML(open(page))

    reversed = []
    doc.css('div#all')[0].css('ul').children.collect{ |li| reversed << li }
    doc.css('div#all')[0].css('ul').children.remove

    div = doc.css('div#all')[0].css('ul')[0]

    url = entry.url
    title = Pollux::tidy(entry.title)

    story = '<li>'
    story += "<b>Pollux</b>: <a href='#{url}' target='_blank'>#{Pollux::truncate(title, 15)}</a>"
    story += '</li>'

    div.add_child(story)
    reversed[0..30].collect{ |li| div.add_child(li) }

    File.open(page, 'w') {|f| f.write(doc.to_xml) }
  end

  def self.truncate(string, word_limit = 5)
    words = string.split(/\s/)
    if words.size >= word_limit 
      last_word = words.last
      words[0,(word_limit-1)].join(" ") + '...' + last_word
    else 
      string
    end
  end

  def self.tidy(text)
    #coder = HTMLEntities.new
    #coder.encode(text)

    text.gsub!(/\n/, ' ')
    text.scan(/[[:print:]]/).join
  end
end


if (1 + rand(4) == 4)
  Pollux::taller
else
  puts "[pollux] Going back to sleep..."
end
