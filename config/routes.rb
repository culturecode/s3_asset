Rails.application.routes.draw do
  match 's3_assets/uploader' => 's3_assets#uploader'
  match 's3_assets/asset_uploaded' => 's3_assets#asset_uploaded', :as => 's3_asset_uploaded'
end