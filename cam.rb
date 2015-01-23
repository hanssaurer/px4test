#!/usr/bin/env ruby

require 'fileutils'
require 'rb_webcam'
require 'RMagick'
include Magick

def take_picture(workingdir)
  capture = Webcam.new(0)

  # Capture 30 frames
  for i in 0..45
    image = capture.grab
    image.save "%s/new_image%d.jpg" % [workingdir, i]
  end
  image = capture.grab
  image.save "%s/still.jpg" % [workingdir]
  capture.close

  # Create a GIF using these frames
  animation = ImageList.new(*Dir["new_image*.jpg"])
  animation.delay = 20
  animation.write("%s/animated.gif" % workingdir)
  FileUtils.rm_rf(Dir.glob("%s/new_image*.jpg" % workingdir))
  return true
end
