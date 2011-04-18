module S3Asset
  module ActsAsS3Asset
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_s3_asset(options = {}); end
      
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
      url = if audio? && size == :thumb
        "/images/audio_thumb.png"
      else
        "#{S3_URL}#{store_path(size)}"
      end

      URI.escape(url)
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

        "#{name_without_extension}.#{extension}"
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
        
        image.resize "800x600"
        image.format "jpg"
        AWS::S3::S3Object.store(store_path(:transcoded), open(image.path), ENV['S3_BUCKET'], :access => :public_read)
        
        image.resize "220x220"
        AWS::S3::S3Object.store(store_path(:thumb), open(image.path), ENV['S3_BUCKET'], :access => :public_read)
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
  end
end

ActiveRecord::Base.send :include, S3Asset::ActsAsS3Asset