class Sys::User < ActiveRecord::Base
  attr_accessible :active, :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin
end
