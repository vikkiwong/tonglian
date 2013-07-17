# encoding: utf-8
class Sys::Group < ActiveRecord::Base
  attr_accessible :name, :user_id

  has_many :user_groups, :class_name => "Sys::UserGroup"
  has_many :users, :through => :user_groups, :source => :user
end
