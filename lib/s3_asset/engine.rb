module S3Asset
  class Engine < Rails::Engine
    # Make S3AssetsHelper available to parent app
    initializer 's3_assets.helper' do |app|
      ActionView::Base.send :include, S3AssetsHelper
      ActionView::Base.send :include, S3FormHelper
    end
  end
end