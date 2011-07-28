require 'right_aws'
require 'mini_magick'
require 'mini_exiftool'
require 'zencoder'

require 's3_asset/engine'
require 's3_asset/acts_as_s3_asset'

S3_URL = "http://#{ENV['S3_BUCKET']}.s3.amazonaws.com/"