require 'rubygems'
require 'yaml'
require 'net/sftp'
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
    puts "Purchasing these items from MOO.com..."
  else
    puts "Your files are available on the web:"
    public_image_urls.each {|url| puts url}
  end
else
  puts "Usage: stripy-photos.rb flickr_user_string limit"
end
