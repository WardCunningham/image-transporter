require 'json'

# wiki utilities

def random
  (1..16).collect {(rand*16).floor.to_s(16)}.join ''
end

def slug title
  title.gsub(/\s/, '-').gsub(/[^A-Za-z0-9-]/, '').downcase()
end

def url text
  text.gsub(/(http:\/\/)?([a-zA-Z0-9._-]+?\.(net|com|org|edu)(\/[^ )]+)?)/,'[http:\/\/\2 \2]')
end

def domain text
  text.gsub(/((https?:\/\/)(www\.)?([a-zA-Z0-9._-]+?\.(net|com|org|edu|us|cn|dk|au))(\/[^ );]*)?)/,'[\1 \4]')
end

# journal actions

def create title
  @journal << {:type => :create, :id => random, :item => {:title => title}, :date => @date}
  @date += 1
end

def add item
  @story << item
  @journal << {:type => :add, :id => item[:id], :item => item, :date => @date}
  @date += 1
end

# story emiters

def item type, object={}
  object[:type] = type
  object[:id] = random()
  add object
end

def paragraph text
  item :paragraph, {:text => text}
end

def image url, caption
  item :image, {:url => url, :text => caption}
end

def page title, date=Time.now.to_i*1000
  @date = date
  @story = []
  @journal = []
  create title
  yield
  page = {:title => title, :story => @story, :journal => @journal}
  JSON.pretty_generate(page)
end

