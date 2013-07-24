# encoding: utf-8
# 字段设置
# t.string   "email",        :null => false   
# t.string   "password"
# t.string   "role",         :null => false
# t.boolean  "allow_access", :default => true   
# t.string   "name",         :default => ""
# t.string   "pinyin",       :default => ""
# t.string   "mobile",       :default => ""
# t.string   "phone",        :default => ""
# t.string   "qq",           :default => ""
# t.datetime "created_at",   :null => false
# t.datetime "updated_at",   :null => false
# t.string   "weixin_id",    :default => ""
# t.string   "family_name",  :default => ""
# t.string   "f_letters",    :default => ""
# t.boolean  "active",       :default => true    # 标志账号是否激活
# t.boolean  "is_valid",        :default => true    # 标志账号是否被删除

class Sys::User < ActiveRecord::Base
  cattr_accessor :skip_callbacks
  attr_accessible :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin, :weixin_id, :password, :family_name, 
                  :f_letters, :pinyin, :skip_callbacks, :active, :is_valid

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => "邮箱格式不正确！"
  #validates_uniqueness_of :email, :message => "此邮箱已存在！", :if => :is_valid?
  validates_format_of :phone, :with => /\d{3}-\d{8}|\d{4}-\d{7}/, :message => "座机格式不正确！", :allow_blank => true
  validates_length_of :mobile, :is => 11, :message => "手机号长度应为11位！", :allow_blank => true
  validates_numericality_of :mobile, :message => "手机号必须是数字！", :allow_blank => true
  validates_length_of :qq, :maximum => 12, :message => "qq号长度不能超过12位！", :allow_blank => true
  validates_numericality_of :qq, :message => "qq号必须是数字！", :allow_blank => true

  has_many :user_groups, :class_name => "Sys::UserGroup"
  has_many :groups, :through => :user_groups, :source => :group
  after_save :name_to_pinyin, :unless => :skip_callbacks

  ROLES = [
    ["普通用户", "member"],
    ["管理员", "manager"]
  ]

  def is_valid?
    self.is_valid == true
  end

  # 显示用户角色中文名
  # ping.wang 2013.07.05
  def role_str
    str = ROLES.find{ |i| i.last == self.role }
    str.present? ? str.first : ""
  end

  # after_save回调方法，将中文名字转为拼音,
  # 注意保存需要skip回调
  # 
  # ping.wang 2013.07.08
  def name_to_pinyin
    pinyin = PinYin.of_string(self.name).join("")
    family_name = PinYin.of_string(self.name.first).join("")
    f_letters = PinYin.abbr(self.name)
    # self.update_column(:pinyin, pinyin) # to skip callbacks  
    Sys::User.skip_callbacks = true
    self.update_attributes(:pinyin => pinyin, :f_letters => f_letters, :family_name => family_name)  # to skip callbacks 
    Sys::User.skip_callbacks = false
  end

  # # 批量导入用户
  # # 
  # # guanzuo.li 2013.07.05  
  # # ping.wang 2013.7.08 修改
  # # wangyang.shen 2013.07.15 修改
  # def self.import_bunch_users(bunch_users)
  #   return false unless bunch_users.present?

  #   wrong_line = []
  #   bunch_users.split("\n").each do |line|
  #     email, name = line.split(/[\,，]+/)   # 匹配中英文逗号分隔符，,
  #     name = name.present? ? name.strip.gsub(/\s+/, "") : ""
  #     email = email.present? ? email.strip.gsub(/\s+/, "") : ""
  #     user = Sys::User.new(:email => email, :name => name, :role => "member")
  #     if user.save
  #       create_message_picture(user)   #为创建成功的用户生成用户图片
  #     else
  #       wrong_line << email      # 将创建出错的邮箱记录下来
  #     end
  #   end
  #   wrong_line
  # end

  #批量导入用户，添加用户分组关联
  #
  #guanzuo.li
  #2013.07.16
  def self.import_group_users(group_users, group)
    return false unless group_users.present?
    wrong_line = []
    success_count = 0
    group_users.split(/[\,，;；]+/).uniq.each do |email|     # 匹配中英文逗号分隔符，, ; ；
      email = email.present? ? email.strip.gsub(/\s+/, "") : ""
      user = Sys::User.find_or_initialize_by_email_and_is_valid(email,true)
      if user.new_record?
        user.role = "member"
        unless user.save
          wrong_line << email      # 将创建出错的邮箱记录下来
        end
      end
      invited_groups_arr = user.invited_groups.split(",")
      if !invited_groups_arr.include?(group.id.to_s)
        Notifier.send_group_invite_mails(user,group)  #为新用户发送邀请邮件
        invited_groups_arr << group.id.to_s
        user.invited_groups = invited_groups_arr.join(",")
        user.save
        success_count += 1
      else
        wrong_line << email
      end
    end
    return wrong_line,success_count
  end

  #圈成员删除后去除此成员对应的圈组邀请记录
  #
  #guanzuo.li
  #2013.07.23
  def self.reset_invited_records(user_id,group_id)
    user = Sys::User.find(user_id)
    if user.present?
      invited_groups_arr = user.invited_groups.split(",")
      invited_groups_arr.delete(group_id.to_s)
      user.invited_groups = invited_groups_arr.join(",")
      user.save
    end
  end

  # 按中文姓名或拼音或邮箱查找用户
  # ================
  # 参数:(查询词)string
  # 
  # ping.wang 2013.07.05

  def self.find_user(str,user)
    group_ids = Sys::UserGroup.where(:user_id => user.id).all.collect(&:group_id)
    return [] unless str.present?
=begin
    if /[\d._@]/.match(str).present?   # 若包含数字或._, 按照email查找
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.email LIKE ? ",group_ids,"%#{str}%"], :limit => 10)
    elsif /^[A-Za-z]+$/.match(str).present?  # 分优先级，按拼音和email查找
      # 先按拼音查找
      # 按首字母
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.f_letters = ? ",group_ids, "#{str}"], :limit => 10)
      # 按姓
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.family_name = ? ",group_ids, "#{str}"], :limit => 10) unless users.present?
      # 匹配全拼,连续
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.pinyin LIKE ? ",group_ids, "%#{str}%"], :limit => 10) unless users.present?
      # 匹配全拼,断续
      regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.pinyin REGEXP ? ",group_ids, regrep_str], :limit => 10) unless users.present?
      # 按邮箱查找
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and and sys_users.email LIKE ? ",group_ids, "%#{str}%"], :limit => 10) unless users.present?
    else  # 按name查找
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.name LIKE ? ",group_ids, "#{str}%"], :limit => 10)   # 按姓查找
      users = Sys::User.includes(:user_groups).find(:all, :conditions => ["sys_user_groups.group_id in (?) and sys_users.name LIKE ? ",group_ids, "%#{str}%"], :limit => 10) unless users.present?   # 若无该姓，按名查找
    end
=end
    select_fields = "sys_users.email,sys_users.role,sys_users.mobile,sys_users.phone,sys_users.name,sys_users.id,u_g.group_id,g.name as group_name"
    join_tag = "join sys_user_groups u_g on sys_users.id = u_g.user_id join sys_groups g on g.id = u_g.group_id"
    if /[\d._@]/.match(str).present?   # 若包含数字或._, 按照email查找
      users = Sys::User.select(select_fields).joins(join_tag).where(["sys_user_groups.group_id in (?) and sys_users.email LIKE ? and sys_users.is_valid = true",group_ids,"%#{str}%"]).limit(10).all
    elsif /^[A-Za-z]+$/.match(str).present?  # 分优先级，按拼音和email查找
      # 先按拼音查找
      # 按首字母
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.f_letters = ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "#{str}"]).limit(10).all
      # 按姓
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.family_name = ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "#{str}"]).limit(10).all unless users.present?
      # 匹配全拼,连续
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.pinyin LIKE ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "%#{str}%"]).limit(10).all unless users.present?
      # 匹配全拼,断续
      regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.pinyin REGEXP ? and sys_users.is_valid = true and g.is_valid = true",group_ids, regrep_str]).limit(10).all unless users.present?
      # 按邮箱查找
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.email LIKE ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "%#{str}%"]).limit(10).all unless users.present?
    else  # 按name查找
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.name LIKE ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "#{str}%"]).limit(10).all   # 按姓查找
      users = Sys::User.select(select_fields).joins(join_tag).where(["u_g.group_id in (?) and sys_users.name LIKE ? and sys_users.is_valid = true and g.is_valid = true",group_ids, "%#{str}%"]).limit(10).all unless users.present?   # 若无该姓，按名查找
    end
    return users
  end

  #确定单个用户微信图文消息参数
  #======Return ======
  #item  Array  [用户参数个数,[用户参数]]
  #liguanzuo
  #2013-07-08
  def item_info
    num = 1
    items = []
    ["email","mobile","phone"].each do |item|
      if self.send(item).present?
        num += 1
        items << item
      end
    end
    [num,items]
  end

  # 登录前检查用户是否存在，及是否允许登陆
  # 
  # ping.wang 2013.07.05
  def self.check_user(email)
    return nil unless email.present?
    sys_user = self.where(:email => email, :is_valid => true).first
    (sys_user.present? && sys_user.allow_access && ["manager","group_manager"].include?(sys_user.role)) ? sys_user : nil
  end

  # #获得用户的信息图片位置
  # #
  # #wangyang.shen 2013-07-15
  # def message_picture()
  #   return "/message_picture/message_picture_#{id}.jpg"
  # end

  # #生成用户信息图片，图片命名规则为message_picture_用户id，存放在/public/message_picture
  # #
  # # wangyang.shen 2013.07.15
  # def self.create_message_picture(user)
  #   img = Magick::Image.read("#{Rails.root}/app/assets/images/picture_background.jpg").first
  #   gc = Magick::Draw.new
  #   gc.stroke('transparent')
  #   gc.font("'#{Rails.root}/app/assets/fonts/FZCYSK.TTF'")
  #   #截取过长的用户信息
  #   name = user.name.length > 4 ? user.name[0..3] : user.name
  #   email = user.email.length > 20 ?  [user.email[0..19] , user.email[20..user.email.length-1]] : [user.email]
  #   mobile,phone,qq = [user.mobile],[user.phone],[user.qq]
  #   gc.text_align(Magick::CenterAlign)
  #   gc.pointsize(40)
  #   user.name.present?? gc.text(90,130,name) : gc.text(90,130,"某位同学")

  #   gc.text_align(Magick::LeftAlign)
  #   gc.pointsize(20)
  #   i = 0
  #   [["邮箱:",email],["电话:",mobile],["座机:",phone],["QQ:",qq]].each do|arr|
  #     arr[1].each_with_index do|value,index|
  #       if index == 0
  #         gc.text(200,75+i*30, "#{arr[0]+value.to_s}") and i=i+1 if value.present?
  #       else
  #         gc.text(245,75+i*30, "#{value.to_s}") and i=i+1 if value.present?
  #       end
  #     end
  #   end

  #   gc.stroke_color("#c7568a")
  #   gc.stroke_width(2)
  #   gc.line(187,60,187,200)

  #   gc.draw(img)
  #   img.write("#{Rails.root}/public/message_picture/message_picture_#{user.id}.jpg")
  # end
end

