namespace :s3_asset do
  desc "Copies required static assets from s3_asset to application's public/ directory"
  task :sync do
    s3_assets = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
    
    command = "cp -R #{s3_assets}/public/plupload #{Rails.root}/public/"
    puts command
    system(command)
    
    command = "rsync -ruv #{s3_assets}/db/migrate #{Rails.root}/db"
    puts command
    system(command)
  end
end
