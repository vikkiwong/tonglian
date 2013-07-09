# encoding: utf-8
class Sys::User < ActiveRecord::Base
  cattr_accessor :skip_callbacks
  attr_accessible :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin, :weixin_id, :password, :family_name, 
                  :f_letters, :pinyin, :skip_callbacks

  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => "邮箱格式不正确！"
  validates_uniqueness_of :email, :message => "此邮箱已存在！"


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
  def self.import_bunch_users(bunch_users)
    return false unless bunch_users.present?

    wrong_line = []
    bunch_users.split("\n").each do |line|
      email, name = line.split(/[\,，]+/)   # 匹配中英文逗号分隔符，,
      name = name.present? ? name.strip.gsub(/\s+/, "") : ""
      email = email.present? ? email.strip.gsub(/\s+/, "") : ""
      user = Sys::User.new(:email => email, :name => name, :role => "member")
      wrong_line << email unless user.save   # 将创建出错的邮箱记录下来
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
    (user.present? && user.allow_access && user.role == "manager") ? user : nil
  end
end
