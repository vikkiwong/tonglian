# encoding: utf-8
class Sys::User < ActiveRecord::Base
  cattr_accessor :skip_callbacks
  attr_accessible :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin, :weixin_id, :password, :family_name, 
                  :f_letters, :pinyin, :skip_callbacks, :message_picture

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => "邮箱格式不正确！"
  validates_uniqueness_of :email, :message => "此邮箱已存在！"
  validates_format_of :phone, :with => /\d{3}-\d{8}|\d{4}-\d{7}/, :message => "座机格式不正确！", :allow_blank => true
  validates_length_of :mobile, :is => 11, :message => "手机号长度应为11位！", :allow_blank => true
  validates_numericality_of :mobile, :message => "手机号必须是数字！", :allow_blank => true
  validates_length_of :qq, :maximum => 12, :message => "qq号长度不能超过12位！", :allow_blank => true
  validates_numericality_of :qq, :message => "qq号必须是数字！", :allow_blank => true
  has_many :user_groups, :class_name => "Sys::UserGroup"

  after_save :name_to_pinyin, :unless => :skip_callbacks

  ROLES = [
    ["普通用户", "member"],
    ["管理员", "manager"]
  ]

  # # validate方法，关联email,active，验证邮箱惟一
  # # 
  # # ping.wang 2013.07.08
  # def email_uniqued?
  #   user =  Sys::User.find_by_email_and_active(self.email, true)
  #   errors.add(:email, "此邮箱已存在！") unless user.present? && user.id == self.id 
  # end

  # 显示用户角色中文名
  # ping.wang 2013.07.05
  def role_str
    str = ROLES.find{ |i| i.last == self.role }
    str.present? ? str.first : ""
  end

  # # 用于显示座机号 如022-58590502
  # # 
  # # ping.wang 2013.07.10
  # def phone_str
  #   self.phone.present? && self.phone.length > 8 ? self.phone.insert(-9, '-') : self.phone
  # end

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

  # 批量导入用户
  # 
  # guanzuo.li 2013.07.05  
  # ping.wang 2013.7.08 修改
  # wangyang.shen 2013.07.15 修改
  def self.import_bunch_users(bunch_users)
    return false unless bunch_users.present?

    wrong_line = []
    bunch_users.split("\n").each do |line|
      email, name = line.split(/[\,，]+/)   # 匹配中英文逗号分隔符，,
      name = name.present? ? name.strip.gsub(/\s+/, "") : ""
      email = email.present? ? email.strip.gsub(/\s+/, "") : ""
      user = Sys::User.new(:email => email, :name => name, :role => "member")
      if user.save
        create_message_picture(user)   #为创建成功的用户生成用户图片
      else
        wrong_line << email      # 将创建出错的邮箱记录下来
      end
    end
    wrong_line
  end

  #批量导入用户，添加用户分组关联
  #
  #guanzuo.li
  #2013.07.16
  def self.import_group_users(group_users,group_id)
    return false unless group_users.present?
    wrong_line = []
    group_users.split("\n").each do |line|
      email, name = line.split(/[\,，]+/)   # 匹配中英文逗号分隔符，,
      name = name.present? ? name.strip.gsub(/\s+/, "") : ""
      email = email.present? ? email.strip.gsub(/\s+/, "") : ""
      user = Sys::User.find_or_initialize_by_email_and_name(email,name)
      if user.new_record?
        user.role = "member"
        if user.save
          create_message_picture(user)   #为创建成功的用户生成用户图片
        else
          wrong_line << email      # 将创建出错的邮箱记录下来
        end
      end
      Sys::UserGroup.create(:user_id => user.id, :group_id => group_id)
    end
    wrong_line
  end

  # 按中文姓名或拼音或邮箱查找用户
  # ================
  # 参数:(查询词)string
  # 
  # ping.wang 2013.07.05
  def self.find_user(str)
    return [] unless str.present?

    if /[\d._@]/.match(str).present?   # 若包含数字或._, 按照email查找
      users = Sys::User.find(:all, :conditions => ["sys_users.email LIKE ? ", "%#{str}%"], :limit => 10) 
    elsif /^[A-Za-z]+$/.match(str).present?  # 分优先级，按拼音和email查找
      # 先按拼音查找
      # 按首字母
      users = Sys::User.find(:all, :conditions => ["sys_users.f_letters = ? ", "#{str}"], :limit => 10)
      # 按姓
      users = Sys::User.find(:all, :conditions => ["sys_users.family_name = ? ", "#{str}"], :limit => 10) unless users.present?
      # 匹配全拼,连续
      users = Sys::User.find(:all, :conditions => ["sys_users.pinyin LIKE ? ", "%#{str}%"], :limit => 10) unless users.present?
      # 匹配全拼,断续
      regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
      users = Sys::User.find(:all, :conditions => ["sys_users.pinyin REGEXP ? ", regrep_str], :limit => 10) unless users.present?
      # 按邮箱查找
      users = Sys::User.find(:all, :conditions => ["and sys_users.email LIKE ? ", "%#{str}%"], :limit => 10) unless users.present?
    else  # 按name查找
      users = Sys::User.find(:all, :conditions => ["sys_users.name LIKE ? ", "#{str}%"], :limit => 10)   # 按姓查找
      users = Sys::User.find(:all, :conditions => ["sys_users.name LIKE ? ", "%#{str}%"], :limit => 10) unless users.present?   # 若无该姓，按名查找 
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
    return nil if !email
    user = where(:email => email).first
    p user
    p ["manager","admin"].include?(user.role)
    (user.present? && user.allow_access && ["manager","admin"].include?(user.role)) ? user : nil
  end

  #获得用户的信息图片位置
  #
  #wangyang.shen 2013-07-15
  def message_picture()
    return "/message_picture/message_picture_#{id}.jpg"
  end

  #生成用户信息图片，图片命名规则为message_picture_用户id，存放在/public/message_picture
  #
  # wangyang.shen 2013.07.15
  def self.create_message_picture(user)
    img = Magick::Image.read("#{Rails.root}/app/assets/images/message_picture_background.jpg").first
    gc = Magick::Draw.new
    gc.stroke('transparent')
    gc.font("'#{Rails.root}/app/assets/fonts/FZCYSK.TTF'")
    #截取过长的用户信息
    name = user.name.length > 4 ? user.name[0..3] : user.name
    email = user.email.length > 20 ?  [user.email[0..19] , user.email[20..user.email.length-1]] : [user.email]
    mobile,phone,qq = [user.mobile],[user.phone],[user.qq]
    gc.text_align(Magick::CenterAlign)
    gc.pointsize(40)
    user.name.present?? gc.text(90,130,name) : gc.text(90,130,"某位同学")

    gc.text_align(Magick::LeftAlign)
    gc.pointsize(20)
    i = 0
    [["邮箱:",email],["电话:",mobile],["座机:",phone],["QQ:",qq]].each do|arr|
      arr[1].each_with_index do|value,index|
        if index == 0
          gc.text(200,75+i*30, "#{arr[0]+value.to_s}") and i=i+1 if value.present?
        else
          gc.text(245,75+i*30, "#{value.to_s}") and i=i+1 if value.present?
        end
      end
    end

    gc.draw(img)
    img.write("#{Rails.root}/public/message_picture/message_picture_#{user.id}.jpg")
  end
end

