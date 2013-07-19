class AddValidToSysUsers < ActiveRecord::Migration
  def change
    add_column :sys_users, :is_valid, :boolean, :default => true
  end
end
