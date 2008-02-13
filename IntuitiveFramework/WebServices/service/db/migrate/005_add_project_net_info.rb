class AddProjectNetInfo < ActiveRecord::Migration
  def self.up
    remove_column :projects, :location
    add_column :projects, :ip_address, :string
    add_column :projects, :port, :integer
    add_column :projects, :connection_id, :integer
    add_column :projects, :branch_number, :string
  end

  def self.down
    add_column :projects, :location, :string
    remove_column :projects, :ip_address
    remove_column :projects, :port
    remove_column :projects, :connection_id
    remove_column :projects, :branch_number
  end
end
