require 'rubygems'
require 'RMagick'
require 'open-uri'
require 'hpricot'
include Magick

class String
  def slugify
    self.downcase.gsub(/&/, ' and ').gsub(/[^a-z0-9']+/, '-').gsub(/^-|-$|'/, '')
  end
end

def get_flickr_photos_for(userstring, limit=nil)
  # TODO:
  # next steps:
  # get by user *name*
  # get the first *78*
  # get the *medium* filesize
  
  user_photos_page = Hpricot(open("http://flickr.com/photos/#{userstring}"))
  atom_url = user_photos_page.search("head link[@type='application/atom+xml']").first[:href]

  user_atom = Hpricot(open(atom_url))
  
  pics = user_atom.search("entry").map {|pic| {:title => pic.search("title").inner_html, :url => pic.search("link[@rel='enclosure']").first[:href]}}
  if limit
    pics = pics.slice(0,limit)
  else
    pics
  end
end

if ARGV[0]

  userstring = ARGV[0]
  limit = ARGV[1].to_i if ARGV[1]
  
  user_pics = get_flickr_photos_for(userstring, limit)
  
  user_pics.each do |title_and_url|
    title = title_and_url[:title]
    url = title_and_url[:url]
  
    image = Image.read(url).first
  
    square_image = image.resize(300,300)
  
    middle_row = square_image.get_pixels(0,150,300,1)
  
    (0..299).each do |n|
      square_image.store_pixels(0, n, 300, 1, middle_row)
    end
  
    output = square_image
  
    filename = "stripey-#{title.slugify}.jpg"
    output.write(filename)
    puts "wrote #{filename}"
  end
else
  puts "Usage: stripey-photos.rb flickr_user_string" # should be "User Name" API_KEY
end

