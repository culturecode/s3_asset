Gem::Specification.new do |s|
  s.name = 's3_asset'
  s.version = '0.1.1'
  s.date = %q{2011-04-18}
  s.email = 'contact@culturecode.ca'
  s.homepage = 'http://github.com/culturecode/s3_asset'
  s.summary = 'Uploads assets directly to S3 using Plupload, then notifies app server immediately.'
  s.authors = ['Ryan Wallace', 'Nicholas Jakobsen']

  s.add_dependency('right_aws')
  s.add_dependency('mini_magick', '~> 3.3')
  s.add_dependency('mini_exiftool')
  s.add_dependency('zencoder')
end
