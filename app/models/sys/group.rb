# encoding: utf-8
class Sys::Group < ActiveRecord::Base
  attr_accessible :name, :user_id
end
