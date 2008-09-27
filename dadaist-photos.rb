require 'rubygems'
require 'yaml'
require 'lib/core_ext/slugify'
require 'lib/flickr_image_processor'

CONFIG = YAML.load_file("config.yml")

if ARGV[0]
  userstring = ARGV[0]
  limit = ARGV[1].to_i if ARGV[1]

  dadaist_processor = DadaistStickers.new(userstring, limit, CONFIG["flickr_api_key"])
  
  processed_images = dadaist_processor.process_each_image
  processed_images.each do |title_and_image|
    filename = "dadaist-#{title_and_image[:title].slugify}.jpg"
    title_and_image[:image].write(filename)
    puts "wrote #{filename}"
  end
else
  puts "Usage: dadaist-photos.rb flickr_user_string limit"
end
