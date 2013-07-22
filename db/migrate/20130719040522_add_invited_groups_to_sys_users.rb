class AddInvitedGroupsToSysUsers < ActiveRecord::Migration
  def change
    add_column :sys_users, :invited_groups, :string, :default => ""
  end
end
