namespace :s3_asset do
  desc "Copies required static assets from s3_asset to application's public/ directory"
  task :sync do
    s3_assets = File.expand_path(File.join(File.dirname(__FILE__), '../..'))

    command = "cp -R #{s3_assets}/public/plupload #{Rails.root}/public/"
    puts command
    system(command)

    command = "cp -R #{s3_assets}/public/javascripts/ #{Rails.root}/public/javascripts/"
    puts command
    system(command)

    command = "rsync -ruv #{s3_assets}/db/migrate #{Rails.root}/db"
    puts command
    system(command)
  end

  desc "Lists all S3 files that aren't linked to an model in the database"
  task :list_orphans, [:model] => :environment do |t, args|
    model = args[:model]

    RightAws::S3.new(ENV['S3_KEY'], ENV['S3_SECRET']).bucket(ENV['S3_BUCKET']).keys('prefix' => model.tableize + '/*').each do |key|
      directory = key.to_s.gsub(/#{model.tableize}\/(\d+)\/.+/, '\1')
      puts key.to_s unless model.constantize.where(:asset_directory => directory).exists?
      puts 'done'
    end
  end
end
