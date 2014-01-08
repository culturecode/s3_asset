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

    count = 0
    orphan_count = 0
    RightAws::S3.new(ENV['S3_KEY'], ENV['S3_SECRET']).bucket(ENV['S3_BUCKET']).keys('prefix' => model.tableize + '/').each do |key|
      directory = key.to_s.gsub(/#{model.tableize}\/(\d+)\/.+/, '\1')

      count += 1
      unless model.constantize.where(:asset_directory => directory).exists?
        puts key.to_s + " is an orphan."
        orphan_count += 1
      end
    end

    puts "#{count} S3 assets. #{orphan_count} are orphans."
  end

  desc "Move all S3 files that aren't linked to an model in the database to the orphan directory (to check if they should really be deleted)"
  task :move_orphans, [:model] => :environment do |t, args|
    model = args[:model]

    count = 0
    orphan_count = 0
    RightAws::S3.new(ENV['S3_KEY'], ENV['S3_SECRET']).bucket(ENV['S3_BUCKET']).keys('prefix' => model.tableize + '/').each do |key|
      directory = key.to_s.gsub(/#{model.tableize}\/(\d+)\/.+/, '\1')

      count += 1
      unless model.constantize.where(:asset_directory => directory).exists?
        puts key.to_s + " is an orphan. moving to orphans/ directory"
        orphan_count += 1
        key.rename('orphans/' + key.to_s)
      end
    end

    puts "#{count} S3 assets. #{orphan_count} are orphans."
  end

  desc "Delete all S3 files that aren't linked to an model in the database"
  task :delete_orphans, [:model] => :environment do |t, args|
    model = args[:model]

    RightAws::S3.new(ENV['S3_KEY'], ENV['S3_SECRET']).bucket(ENV['S3_BUCKET']).keys('prefix' => model.tableize + '/').each do |key|
      directory = key.to_s.gsub(/#{model.tableize}\/(\d+)\/.+/, '\1')

      unless model.constantize.where(:asset_directory => directory).exists?
        puts key.to_s + " is an orphan. deleting..." unless model.constantize.where(:asset_directory => directory).exists?
        key.delete
      end
    end
  end
end
