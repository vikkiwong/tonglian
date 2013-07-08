class AddFamilyNameAndFLettersToSysUsers < ActiveRecord::Migration
  def change
    add_column :sys_users, :family_name, :string, :default => ""
    add_column :sys_users, :f_letters, :string, :default => ""
  end
end
