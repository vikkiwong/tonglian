class RemoveWeixinAndWeiboAndBlogFromSysUsers < ActiveRecord::Migration
  def up
    remove_column :sys_users, :weixin
    remove_column :sys_users, :weibo
    remove_column :sys_users, :blog
    remove_column :sys_users, :sex
  end

  def down
    add_column :sys_users, :blog, :string
    add_column :sys_users, :weibo, :string
    add_column :sys_users, :weixin, :string
    add_column :sys_users, :sex, :string
  end
end
