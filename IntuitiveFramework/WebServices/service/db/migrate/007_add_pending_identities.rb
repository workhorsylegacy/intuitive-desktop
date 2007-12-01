class AddPendingIdentities < ActiveRecord::Migration
  def self.up
    create_table :pending_identities do |t|
        t.column :name, :string, :null => false
        t.column :description, :text, :null => false
        t.column :public_key, :text, :null => false
        t.column :ip_address, :string, :null => false
        t.column :port, :integer, :null => false
        t.column :connection_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :pending_identities
  end
end
