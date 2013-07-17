#encoding: utf-8
namespace :utils do
  desc "Create user picture for all users"
  task :create_message_picture => :environment do
    Sys::User.all.each do |user|
      Sys::User.create_message_picture(user)
      puts "用户#{user.id}图片创建成功"
    end if Sys::User.all.present?
  end
  desc "Create group picture for all users"
  task :create_group_picture => :environment do
    Sys::Group.all.each do |group|
      Sys::Group.create_group_picture(group)
      puts "小组#{group.id}图片创建成功"
    end if Sys::Group.all.present?
  end
  desc "add many group"
  task :add_groups => :environment do
    (0..10).each do |i|
      group = Sys::Group.new(:name => "小组#{i}", :user_id => 1)
      group.save
    end
  end
end