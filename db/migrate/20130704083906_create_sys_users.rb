class CreateSysUsers < ActiveRecord::Migration
  def change
    create_table :sys_users do |t|
      t.integer :id, :null => false
      t.string :email, :null => false
      t.string :password
      t.string :role, :null => false
      t.boolean :allow_access, :default => true
      t.boolean :active, :default => true
      t.string :name, :default => ""
      t.string :pinyin, :default => ""
      t.string :sex, :default => ""
      t.string :mobile, :default => ""
      t.string :phone, :default => ""
      t.string :qq, :default => ""
      t.string :weixin, :default => ""
      t.string :weibo, :default => ""
      t.string :blog, :default => ""

      t.timestamps
    end
  end
end
