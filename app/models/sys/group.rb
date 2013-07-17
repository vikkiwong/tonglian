# encoding: utf-8
class Sys::Group < ActiveRecord::Base
  attr_accessible :id, :name, :user_id, :group_picture

  has_many :user_groups, :class_name => "Sys::UserGroup"
  has_many :users, :through => :user_groups, :source => :user
  def group_picture
    return "/group_picture/group_picture_#{id}.jpg"
  end
  def self.create_group_picture(group)
    img = Magick::Image.read("#{Rails.root}/app/assets/images/picture_background.jpg").first
    gc = Magick::Draw.new
    gc.stroke('transparent')
    gc.font("'#{Rails.root}/app/assets/fonts/FZCYSK.TTF'")
    gc.text_align(Magick::CenterAlign)
    gc.pointsize(60)
    group.name.present?? gc.text(260,80,group.name) : gc.text(260,80,"微信通联")
    gc.stroke_color("#c7568a")
    gc.stroke_width(5)
    gc.line(20,120,500,120)
    gc.draw(img)
    img.write("#{Rails.root}/public/group_picture/group_picture_#{group.id}.jpg")
  end
end
