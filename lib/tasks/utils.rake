#encoding: utf-8
namespace :utils do
  desc "Create user picture for all users"
  task :create_message_picture => :environment do
     Sys::User.all.each do |user|
       Sys::User.create_message_picture(user)
       puts "用户#{user.id}图片创建成功"
     end if Sys::User.all.present?
  end
end