#!/usr/bin/env ruby

require 'rb_webcam'
require 'RMagick'
include Magick

capture = Webcam.new(0)

# Capture 30 frames
for i in 0..30
  image = capture.grab
  image.save "new_image%d.jpg" % i
end
capture.close

# Create a GIF using these frames
animation = ImageList.new(*Dir["*.jpg"])
animation.delay = 10
animation.write("animated.gif")
