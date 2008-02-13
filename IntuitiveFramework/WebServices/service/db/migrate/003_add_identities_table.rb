class AddIdentitiesTable < ActiveRecord::Migration
  def self.up
    create_table :identities do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :user_id, :string
    end
  end

  def self.down
    drop_table :identities
  end
end
