class AddActiveToSysUsers < ActiveRecord::Migration
  def change
    add_column :sys_users, :active, :boolean, :default => true
  end
end
