class CreateSysGroups < ActiveRecord::Migration
  def change
    create_table :sys_groups do |t|
      t.integer :user_id, :null => false
      t.string :name

      t.timestamps
    end
  end
end
