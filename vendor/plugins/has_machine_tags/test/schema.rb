ActiveRecord::Schema.define(:version => 0) do
  create_table :taggable_models do |t|
    t.string  :title, :default => ''
  end

  create_table :tags do |t|
    t.string :name, :default => ''
    t.string :kind, :default => '' 
  end

  create_table :taggings do |t|
    t.integer :tag_id

    t.string  :taggable_type, :default => ''
    t.integer :taggable_id
  end
end
