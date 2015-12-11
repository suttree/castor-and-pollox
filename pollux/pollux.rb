require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'
require 'summarize'
require 'pismo'

class Pollux
  def self.taller
    @config = YAML::load(File.open('/home/suttree/public_html/troisen.com/gemini/config/pollux.yml'))

    url = @config['urls'].sort_by{ rand }[0]
    feed = FeedNormalizer::FeedNormalizer.parse open(url)
    entry = feed.entries.sort_by{ rand }.first
    entry.clean! rescue nil

    doc = Pismo[entry.id]

    summary, topics = Nokogiri::HTML(doc.body).text.summarize(:ratio => 25, :topics => true)
    summary = summary.scan(/[^\.!?]+[\.!?]/).map(&:strip)[0..2].flatten.join(' ') rescue summary.truncate(150)
    #puts summary.inspect
    #puts topics.inspect

    page = '/home/suttree/public_html/troisen.com/public/cap.html'
    doc = Nokogiri::HTML(open(page))

    reversed = []
    doc.css('div#all')[0].css('ul').children.collect{ |li| reversed << li }
    doc.css('div#all')[0].css('ul').children.remove

    div = doc.css('div#all')[0].css('ul')[0]

    url = entry.url || feed.url
    title = Pollux::tidy(entry.title)
    summary = Pollux::tidy(summary)
    summary = '<br>' + summary + '<br>'  unless (summary.nil? || summary.empty?)

    story = "<li id='pollux'><p><a href='#{url}' target='_blank'>#{Pollux::truncate(title, 20)}</a><small>#{summary}<b>~ Pollux</b></small></p></li>"

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
    return '' unless text

    coder = HTMLEntities.new
    coder.encode(text)

    text.gsub!(/\n/, ' ')
    text.scan(/[[:print:]]/).join
  end
end


probability = 5
if (rand(9) > probability)
  Pollux::taller
else
  puts "[pollux] Going back to sleep..."
end
