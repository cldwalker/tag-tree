class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :name
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.string   :objectable_type, :limit => 30
      t.integer  :objectable_id
      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
