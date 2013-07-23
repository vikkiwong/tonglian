class AddIndexesToSysUsersAndSysUserGroups < ActiveRecord::Migration
  def change
    add_index :sys_users, [:pinyin, :is_valid], :name => "_idx_by_pinyin_and_is_valid"
    add_index :sys_user_groups, [:user_id], :name => "_idx_by_user_id"
    add_index :sys_user_groups, [:group_id], :name => "_idx_by_group_id"
  end
end
