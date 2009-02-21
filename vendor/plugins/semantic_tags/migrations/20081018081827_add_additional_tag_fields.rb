class AddAdditionalTagFields < ActiveRecord::Migration
  def self.up
    add_column :tags, :description, :string
    add_column :tags, :created_at, :datetime
  end

  def self.down
    remove_column :tags, :description
    remove_column :tags, :created_at
  end
end
