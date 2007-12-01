class RenamePublicKeys < ActiveRecord::Migration
  def self.up
    rename_column :identities, :user_id, :public_key
    rename_column :projects, :user_id, :public_key
  end

  def self.down
    rename_column :identities, :public_key, :user_id
    rename_column :projects, :public_key, :user_id
  end
end
