Rails.application.routes.draw do
  match 's3_assets/uploader' => 's3_assets#uploader', via: [:get, :post]
  match 's3_assets/asset_uploaded' => 's3_assets#asset_uploaded', :as => 's3_asset_uploaded', via: [:get, :post]
end
