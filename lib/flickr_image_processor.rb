require 'rubygems'
require 'RMagick'
require 'open-uri'
require 'net/flickr'
include Magick

class FlickrImageProcessor
  def initialize(email, limit, api_key)
    flickr = Net::Flickr.new(api_key)
    @pics = []
    
    flickr.people.find_by_email(email).photos("per_page" => limit).each do |photo|
      title = photo.title
      url = photo.source_url(:medium)
      
      @pics << {:title => title, :url => url}
    end
  end
  
  def process_each_image
    raise "This method should be implemented in subclasses."
  end
end

class StripyStickers < FlickrImageProcessor
  def process_each_image
    @pics.map do |title_and_url|
      title = title_and_url[:title]
      url = title_and_url[:url]

      image = Image.read(url).first

      square_image = image.resize(500,500)

      middle_row = square_image.get_pixels(0,250,500,1)

      (0..499).each do |n|
        square_image.store_pixels(0, n, 500, 1, middle_row)
      end

      output = square_image
      
      {:title => title, :image => output}
    end
  end
end

class DadaistStickers < FlickrImageProcessor
  def process_each_image
    @pics.map do |title_and_url|
      title = title_and_url[:title]
      url = title_and_url[:url]
      
      image = Image.read(url).first

      avcol = average_color(image)

      color = Pixel.new(avcol[:red], avcol[:green], avcol[:blue])

      background = Magick::Image.new(500, 500) { self.background_color = color }

      caption = Magick::Image.read("caption:#{title}") do
        self.size = "288x288"
        self.pointsize = 25
        self.background_color = "none"
        self.font = "Helvetica Neue Light"
        self.fill = "white"
        self.gravity = SouthWestGravity
      end

      output = background.composite(caption[0], Magick::CenterGravity, Magick::OverCompositeOp)

      {:title => title, :image => output}
    end
  end
  
  private
  
  def average_color(image)
    red, green, blue = 0, 0, 0
    image.each_pixel { |pixel, c, r|
      red += pixel.red
      green += pixel.green
      blue += pixel.blue
    }
    num_pixels = image.bounding_box.width * image.bounding_box.height
    return {:red => red/num_pixels, :green => green/num_pixels, :blue => blue/num_pixels}  
  end
  
end