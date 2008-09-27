require 'rubygems'
require 'RMagick'
require 'open-uri'
require 'hpricot'
include Magick

class FlickrImageProcessor
  def initialize(userstring, limit, api_key)
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
      @pics = pics.slice(0,limit)
    else
      @pics = pics
    end
  end
  
  def process_each_image
    raise "This method should be implemented in subclasses."
  end
end

class StripeyStickers < FlickrImageProcessor
  def initialize(*args)
    super
  end
  
  def process_each_image
    @pics.map do |title_and_url|
      title = title_and_url[:title]
      url = title_and_url[:url]

      image = Image.read(url).first

      square_image = image.resize(300,300)

      middle_row = square_image.get_pixels(0,150,300,1)

      (0..299).each do |n|
        square_image.store_pixels(0, n, 300, 1, middle_row)
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

      background = Magick::Image.new(300, 300) { self.background_color = color }

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