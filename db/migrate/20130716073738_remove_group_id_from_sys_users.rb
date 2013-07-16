class RemoveGroupIdFromSysUsers < ActiveRecord::Migration
  def up
    remove_column :sys_users, :group_id
  end

  def down
    add_column :sys_users, :group_id, :integer
  end
end
