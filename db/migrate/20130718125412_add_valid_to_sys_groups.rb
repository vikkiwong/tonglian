class AddValidToSysGroups < ActiveRecord::Migration
  def change
    add_column :sys_groups, :is_valid, :boolean, :default => true
  end
end
