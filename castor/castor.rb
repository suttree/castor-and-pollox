require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'

class Castor
  def self.taller
    coder = HTMLEntities.new

    @config = YAML::load(File.open('/home/suttree/public_html/troisen.com/gemini/config/castor.yml'))

    url = @config['urls'].sort_by{ rand }[0]
    feed = FeedNormalizer::FeedNormalizer.parse open(url)
    entry = feed.entries.sort_by{ rand }.first
    entry.clean!

    page = '/home/suttree/public_html/troisen.com/public/test.html'
    doc = Nokogiri::HTML(open(page))
    div = doc.css('div#all')[0].css('ul')[0]

    story = '<li>'
    story += "<a href='#{entry.url}' target='_blank'>#{coder.encode(Castor::truncate(entry.title, 70))}</a>"
    story += '</li>'
    
    div.add_child(story)

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
end


if (1 + rand(3) == 3)
  Castor::taller
else
  puts "Going back to sleep..."
end
