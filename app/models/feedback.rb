class Feedback < ActiveRecord::Base
  attr_accessor :email,:user_id,:message
end