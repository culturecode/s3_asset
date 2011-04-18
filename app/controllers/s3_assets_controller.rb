class S3AssetsController < ApplicationController
  unloadable
  
  def asset_uploaded
    klass = params[:object_type].classify.constantize
    
    klass.delay.transcode_asset(params[:s3_upload])
    @asset = klass.new(params[:s3_upload])
  end
end