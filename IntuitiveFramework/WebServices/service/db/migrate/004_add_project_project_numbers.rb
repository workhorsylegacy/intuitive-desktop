class AddProjectProjectNumbers < ActiveRecord::Migration
  def self.up
    add_column :projects, :project_number, :string
  end

  def self.down
    remove_column :projects, :project_number, :string
  end
end
