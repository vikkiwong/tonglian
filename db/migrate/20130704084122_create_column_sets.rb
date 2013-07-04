class CreateColumnSets < ActiveRecord::Migration
  def change
    create_table :column_sets do |t|
      t.integer :id, :null => false
      t.string :column_name, :null => false
      t.boolean :active, :default => true

      t.timestamps
    end
  end
end
