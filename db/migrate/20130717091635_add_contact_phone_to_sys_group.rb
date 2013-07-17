class AddContactPhoneToSysGroup < ActiveRecord::Migration
  def change
    add_column :sys_groups, :contact_phone, :string, :default => ""
  end
end
