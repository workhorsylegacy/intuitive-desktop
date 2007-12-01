class AddIdentityConnection < ActiveRecord::Migration
  def self.up
    add_column :identities, :port, :integer
    add_column :identities, :connection_id, :integer
    add_column :identities, :branch_number,  :string
  end

  def self.down
    remove_column :identities, :port
    remove_column :identities, :connection_id
    remove_column :identities, :branch_number
  end
end
