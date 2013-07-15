class Feedback < ActiveRecord::Base
  attr_accessible :email,:user_id,:message
end