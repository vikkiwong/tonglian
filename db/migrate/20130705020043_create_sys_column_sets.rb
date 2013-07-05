class CreateSysColumnSets < ActiveRecord::Migration
  def change
    create_table :sys_column_sets do |t|
      t.string :column_name, :null => false
      t.boolean :active, :default => true

      t.timestamps
    end
  end
end
