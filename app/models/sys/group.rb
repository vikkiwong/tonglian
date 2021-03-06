# encoding: utf-8
# 字段设置
# t.integer  "user_id",       :null => false
# t.string   "name"
# t.datetime "created_at",    :null => false
# t.datetime "updated_at",    :null => false
# t.string   "contact_phone", :default => ""
# t.boolean  "active",        :default => true    # 标志账号是否激活
# t.boolean  "is_valid",         :default => true    # 标志账号是否被删除

class Sys::Group < ActiveRecord::Base
  attr_accessible :id, :name, :user_id, :group_picture, :contact_phone, :create_user, :created_at, :active, :is_valid

  validates_presence_of :name,  :message => "圈子名不能为空！"

  has_many :user_groups, :class_name => "Sys::UserGroup"
  has_many :users, :through => :user_groups, :source => :user

  scope :is_valided, :conditions => { :is_valid => true }
  scope :ordered, :order => "sys_groups.id DESC"
  
  #获得创建人的信息
  #
  #wangyang.shen 2013-07-17
  def create_user
    Sys::User.find_by_id(user_id)
  end

  #获得小组的信息图片位置
  #
  #wangyang.shen 2013-07-17
  def group_picture
    "/group_picture/group_picture_#{id}.jpg"
  end

  #分解用户同意邀请链接所包含数据
  #
  #guanzuo.li
  #2013.07.24
  def self.analyze_source(source)
    source_arr = source.split("&")
    group_id = source_arr[1].to_i
    user_id = source_arr[0].to_i
    send_time = Time.parse(source_arr[2])
    return group_id,user_id,send_time
  end

  #生成小组信息图片，图片命名规则为group_picture_小组id，存放在/public/group_picture
  #
  # wangyang.shen 2013.07.17
  def self.create_group_picture(group)
    #获取背景图片，初始化画笔,设置字体
    img = Magick::Image.read("#{Rails.root}/app/assets/images/picture_background.jpg").first
    gc = Magick::Draw.new
    gc.stroke('transparent')
    gc.font("'#{Rails.root}/app/assets/fonts/FZCYSK.TTF'")
    #绘制标题
    gc.text_align(Magick::CenterAlign)
    gc.pointsize(60)
    gc.kerning(10)
    group.name.present?? gc.text(260,130,group.name) : gc.text(260,130,"圈子名称")
    #绘制电话
    gc.kerning(10)
    gc.pointsize(30)
    group.contact_phone.present?? gc.text(260,220,group.contact_phone) : gc.text(260,220,"还没有联系方式")
    #绘制分割线
    gc.stroke_color("#c7568a")
    gc.stroke_width(3)
    gc.line(60,180,460,180)
    gc.draw(img)
    img.write("#{Rails.root}/public/group_picture/group_picture_#{group.id}.jpg")
  end
end
