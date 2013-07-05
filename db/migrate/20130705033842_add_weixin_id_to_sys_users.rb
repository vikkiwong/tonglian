class AddWeixinIdToSysUsers < ActiveRecord::Migration
  def change
      add_column :sys_users, :weixin_id, :string, :default => ''
  end
end
