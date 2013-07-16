class AddGroupIdToSysUsers < ActiveRecord::Migration
  def change
    add_column :sys_users, :group_id, :integer
  end
end
