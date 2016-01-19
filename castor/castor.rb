# encoding: UTF-8

require 'rubygems'
require 'yaml'
require 'feed-normalizer'
require 'open-uri'
require 'open_uri_redirections'
require 'nokogiri'
require 'readability'
require 'htmlentities'
require 'summarize'
require 'sanitize'
require 'iconv'
require 'uri'

class Castor
  def self.taller
    @config = YAML::load(File.open('/home/suttree/public_html/troisen.com/gemini/config/castor.yml'))

    url = @config['urls'].sort_by{ rand }[0]
    puts url
    feed = FeedNormalizer::FeedNormalizer.parse open(url, :allow_redirections => :safe)
    entry = feed.entries.sort_by{ rand }.first
    entry.clean! rescue nil

    # handle atom feeds, e.g. Google Trends
    source = if feed.parser == 'SimpleRSS'
      open(URI.extract(entry.content).sort_by{ rand }.first, :allow_redirections => :safe).read
    else
      open(entry.urls.first, :allow_redirections => :safe).read
    end
    content = Readability::Document.new(source).content

    summary, topics = content.summarize(:ratio => 5, :topics => true)

    summary = summary.scan(/[^\.!?]+[\.!?]/).map(&:strip)[0..2].flatten.join(' ') rescue summary.truncate(150)
    summary = Sanitize.clean(summary).strip!

    page = '/home/suttree/public_html/troisen.com/public/cap.html'
    doc = Nokogiri::HTML(open(page))
    doc.encoding = 'utf-8'

    reversed = []
    doc.css('div#all')[0].css('ul').children.collect{ |li| reversed << li }
    doc.css('div#all')[0].css('ul').children.remove

    div = doc.css('div#all')[0].css('ul')[0]

    url = entry.url || feed.url
    title = Castor::tidy(entry.title)
    summary = Castor::tidy(summary)
    summary = '<br>' + summary + '<br>' unless (summary.nil? || summary.empty?)

    story = "<li id='castor'><a href='#{url}' target='_blank'>#{Castor::truncate(title, 20)}</a><small>#{summary}</small></li>"

    div.add_child(story)
    reversed[0..30].collect{ |li| div.add_child(li) }

    File.open(page, 'w:utf-8') {|f| f.write(doc.to_html) }
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

    #coder = HTMLEntities.new
    #text = coder.encode(text) rescue text
    #text = coder.decode(text) rescue text

    #text.gsub!(/\n/, ' ')
    #text.scan(/[[:print:]]/).join
    #text = Iconv.conv('ASCII//IGNORE', 'UTF8', text)

    # From http://kevinquillen.com/programming/2014/06/23/ruby-gets-shit-done/
    text.gsub!(/"/, "'");
    text.gsub!(/\u2018/, "'");
    text.gsub!(/[”“]/, '"');
    text.gsub!(/’/, "'");
    text.gsub!(/(\r)?\n/, "");
    text.gsub!(/\s+/, ' ');

    if String.method_defined?(:encode)
      text.encode!('UTF-8', 'UTF-8', :invalid => :replace)
    else
      ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
      text = ic.iconv(text)
    end
    text
  end
end


probability = 5
if (rand(9) > probability)
  Castor::taller
else
  puts "[castor] Going back to sleep..."
end
