
class AddIdentityConnectionSocket < ActiveRecord::Migration
  def self.up
    add_column :identities, :ip_address, :string
  end

  def self.down
    rename_column :identities, :ip_address
  end
end
