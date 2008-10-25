class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.string :name, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :urls
  end
end
