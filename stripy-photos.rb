require 'rubygems'
require 'yaml'
require 'net/sftp'
require 'htmlentities'
require 'moo'
require 'lib/core_ext/slugify'
require 'lib/flickr_image_processor'

CONFIG = YAML.load_file("config.yml")

if ARGV[0]
  userstring = ARGV[0]
  if ARGV[1]
    limit = ARGV[1].to_i
  else
    limit = 90
  end

  stripes_processor = StripyStickers.new(userstring, limit, CONFIG["flickr_api_key"])
  
  processed_images = stripes_processor.process_each_image
  public_image_urls = []
  
  # write those images to our SFTP server.
  Net::SFTP.start(CONFIG["ftp"]["host"],
                  CONFIG["ftp"]["username"],
                  :password => CONFIG["ftp"]["password"]) do |sftp|
    processed_images.each do |title_and_image|
      filename = "stripy-#{title_and_image[:title].slugify}.jpg"
      sftp.file.open("#{CONFIG["ftp"]["full_upload_path"]}#{filename}", "w") do |f|
        f.write(title_and_image[:image].to_blob {|i| i.format = "JPG"})
        public_image_urls << "#{CONFIG["ftp"]["public_url_root"]}#{filename}"
      end
    end
  end
  
  if ARGV[2].eql?("purchase")
    puts "Creating an order for these items from MOO.com..."
    order = Moo::Order.new(:api_key => CONFIG["moo_api_key"])
    public_image_urls.each do |url|
      sticker = Moo::Sticker.new(:url => url)
      order.designs << sticker
    end
    
    order.submit
    if order.error?
      puts "There was a problem with your order:"
      puts order.error_string
    else
      puts "Your order was successfully created. Now visit the website for payment:"
      coder = HTMLEntities.new
      puts coder.decode(order.start_url)
    end
  elsif ARGV[2].eql?("preview")
    puts "Previewing your Moo API XML"
    order = Moo::Order.new(:api_key => CONFIG["moo_api_key"])
    public_image_urls.each do |url|
      sticker = Moo::Sticker.new(:url => url)
      order.designs << sticker
    end
    
    puts order.to_xml
  else
    puts "Your files are available on the web:"
    public_image_urls.each {|url| puts url}
  end
else
  puts "Usage: stripy-photos.rb flickr_user_string limit"
end
