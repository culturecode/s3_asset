namespace :s3_asset do
  desc "Copies required static assets from s3_asset to application's public/ directory"
  task :import_assets do
    s3_assets = File.expand_path(File.join(File.dirname(__FILE__), '../../public/plupload'))
    command = "cp -R #{s3_assets} #{Rails.root}/public/"
    puts command
    system(command)
  end
end
