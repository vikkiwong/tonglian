class RemoveActiveFromSysUsers < ActiveRecord::Migration
  def up
    remove_column :sys_users, :active
  end

  def down
    add_column :sys_users, :active, :boolean
  end
end
