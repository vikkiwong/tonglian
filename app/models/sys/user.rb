class Sys::User < ActiveRecord::Base
  attr_accessible :active, :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin

  def self.import_users(data)
    success_count = 0
    fail_count = 0
    data.strip.gsub(" ", "").gsub("\r","").split("\n").each do |line|
      value = line.split(",")
      sql_str="insert into sys_users (name,email) values ('#{value[0]}','#{value[1]}')"
      begin
        Sys::User.connection.execute(sql_str)
        success_count += 1
      rescue Exception => e
        puts e.message
        fail_count += 1
      end
    end

  end
end
