module S3Asset
  class Engine < Rails::Engine
    # Make S3AssetsHelper available to parent app
    initializer 's3_assets.helper' do |app|
      ActionView::Base.send :include, S3AssetsHelper
    end
  end
end