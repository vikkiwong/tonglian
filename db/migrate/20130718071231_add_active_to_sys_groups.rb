class AddActiveToSysGroups < ActiveRecord::Migration
  def change
    add_column :sys_groups, :active, :boolean, :default => true
  end
end
