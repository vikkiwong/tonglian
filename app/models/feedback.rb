# encoding: utf-8
class Feedback < ActiveRecord::Base
  attr_accessible :email,:user_id,:message

  belongs_to :sys_user, :class_name => "Sys::User", :foreign_key => "user_id"

  scope :releated_find, :include => :sys_user
  scope :ordered, :order => "feedbacks.id DESC"
end