module S3Asset
  module ActsAsS3Asset
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_s3_asset(options = {})
        options.reverse_merge!(:crop => true)
        
        cattr_accessor :asset_options
        self.asset_options = options
        
        before_create :set_asset_created_at if attribute_method?(:asset_created_at)
      end
      
      def transcode_asset(options = {})
        new(options).transcode_asset
      end
    end
    
    # Returns whether the asset has been persisted to S3
    def asset_persisted?
      asset_directory.present? && asset_name.present?
    end

    def asset_url(size = :original)
      # Special case of one size fits all audio thumbnail
      if audio? && size == :thumb
        "/images/audio_thumb.png"
      elsif !(video? || audio? || image?) && size == :thumb
        "/images/file_thumb.png"
      else
        "#{S3_URL}#{store_path(size)}"
      end
    end

    def store_path(size = :original)
      "#{store_dir(size)}/#{asset_with_extension(size)}"
    end

    def store_dir(size)
      "#{self.class.table_name}/#{self.asset_directory}/#{size}"
    end

    def asset_with_extension(size = :original)
      # Use original extension for original size
      if size == :original
        self.asset_name

      # Special case of video thumbnails created by Zencoder
      elsif video? && size == :thumb
        "frame_0000.jpg"
      # Regular case
      else
        name_without_extension = File.basename(self.asset_name, File.extname(self.asset_name))
        original_extension = File.extname(self.asset_name)[1..-1]

        extension_hash = if image?
          {:thumb => 'jpg', :transcoded => 'jpg'}
        elsif video?
          {:transcoded => 'mp4'}
        elsif audio?
          {:transcoded => 'mp3'}
        else
          {}
        end

        extension = extension_hash[size] || original_extension

        URI.escape("#{name_without_extension}.#{extension}")
      end
    end

    def transcode_asset
      if video?
        Zencoder::Job.create(:input => asset_url, 
                             :output => {:public => 1,
                                         :width => '640', 
                                         :height => '480', 
                                         :url => asset_url(:transcoded), 
                                         :thumbnails => {:number => 1, :format => 'jpg', :aspect_mode => "crop", :size => "220x220", :base_url => S3_URL + store_dir(:thumb)}})
      elsif audio?
        Zencoder::Job.create(:input => asset_url, :output => {:public => 1, :url => asset_url(:transcoded)})
      elsif image?
        AWS::S3::Base.establish_connection!(:access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'])
        image = MiniMagick::Image.open(asset_url)
        
        if self.class.attribute_method?(:asset_created_at)
          AssetMetadataCache.create(:asset_directory => asset_directory, :asset_created_at => MiniExiftool.new(image.path).date_time_original)
        end
        
        image.resize "800x600"
        image.format "jpg"
        AWS::S3::S3Object.store(store_path(:transcoded), open(image.path), ENV['S3_BUCKET'], :access => :public_read)
        
        if self.class.asset_options[:crop] == true
         crop_resized(image, 220, 220)
        else
          image.resize "220x220"
        end
        
        AWS::S3::S3Object.store(store_path(:thumb), open(image.path), ENV['S3_BUCKET'], :access => :public_read)
      end
    end
    
    def set_asset_created_at
      metadata = AssetMetadataCache.find_by_asset_directory(asset_directory)
      
      if metadata.present? 
        self.asset_created_at = metadata.asset_created_at
        metadata.delete
      end
    end

    def video?
      asset_content_type =~ /video/ || [ 'application/x-mp4', 'flv-application/octet-stream'].include?(asset_content_type)
    end

    def audio?
      asset_content_type =~ /audio/ || ['application/x-mp3', 'application/x-wma'].include?(asset_content_type)
    end

    def image?
      asset_content_type =~ /image/
    end
    
    # Scale an image down and crop away any extra to achieve a certain size.
    # This is handy for creating thumbnails of the same dimensions without
    # changing the aspect ratio.
    def crop_resized(image, width, height, gravity = "Center")
      width = width.to_i
      height = height.to_i

      # Grab the width and height of the current image in one go.
      cols, rows = image[:dimensions]
      
      # Only do anything if needs be. Who knows, maybe it's already the exact
      # dimensions we're looking for.
      if(width != cols && height != rows)
        image.combine_options do |c|
          # Scale the image down to the widest dimension.
          if(width != cols || height != rows)
            scale = [width / cols.to_f, height / rows.to_f].max * 100
            c.resize("#{scale}%")
          end

          # Align how things will be cropped.
          c.gravity(gravity)

          # Crop the image to size.
          c.crop("#{width}x#{height}+0+0")
        end
      end
    end
    
  end
end

ActiveRecord::Base.send :include, S3Asset::ActsAsS3Asset