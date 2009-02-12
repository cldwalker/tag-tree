class AddMachineTags < ActiveRecord::Migration
  def self.up
    add_column :tags, :namespace, :string
    add_column :tags, :predicate, :string
    add_column :tags, :value, :string
  end

  def self.down
    remove_column :tags, :namespace, :string
    remove_column :tags, :predicate, :string
    remove_column :tags, :value, :string
  end
end
