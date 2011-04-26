class CreateAssetMetadataCaches < ActiveRecord::Migration
  def self.up
    create_table :asset_metadata_caches do |t|
      t.string :asset_directory
      t.datetime :asset_created_at
    end
  end

  def self.down
    drop_table :asset_metadata_caches
  end
end
