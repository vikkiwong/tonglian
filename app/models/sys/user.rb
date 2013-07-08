# encoding: utf-8
class Sys::User < ActiveRecord::Base
  attr_accessible :active, :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin, :weixin_id, :password
  validates_uniqueness_of :email, :message => "此邮箱已存在！"
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  before_save :name_to_pinyin

  scope :actived, :conditions => ["sys_users.active = ? or sys_users.active is NULL", true]

  ROLES = [
    ["普通用户", "member"],
    ["管理员", "manager"]
  ]

  # 显示用户角色中文名
  # ping.wang 2013.07.05
  def role_str
    str = ROLES.find{ |i| i.last == self.role }
    str.present? ? str.first : ""
  end

  # after_save回调方法，将中文名字转为拼音,
  # 注意保存时不能用.save方法，否则会反复回调
  # 
  # ping.wang 2013.07.08
  def name_to_pinyin
    pinyin = PinYin.permlink(self.name)
    self.update_column(:pinyin, pinyin)   # to skip callbacks
  end

  # 批量导入用户
  # 
  # guanzuo.li 2013.07.05  
  # ping.wang 2013.7.08 修改 
  def self.import_bunch_users(bunch_users)
    wrong_line = []
    return false unless bunch_users.present?
    bunch_users.split("\n").each do |line|
      email, name = line.split(/[\,，]+/)   # 匹配中英文逗号分隔符，,
      name = name.present? ? name.strip.gsub(/\s+/, "") : ""
      email = email.present? ? email.strip.gsub(/\s+/, "") : ""
      user = Sys::User.new(:email => email, :name => name, :role => "member")
      wrong_line << email unless user.save   # 将创建出错的邮箱记录下来
    end
    wrong_line
    #success_count, fail_count = 0, 0
    # bunch_users.strip.gsub(" ", "").gsub("\r","").split("\n").each do |line|
    #   value = line.split(",")
    #   sql_str="insert into sys_users (name,email) values ('#{value[0]}','#{value[1]}')"
    #   begin
    #     Sys::User.connection.execute(sql_str)
    #     success_count += 1
    #   rescue Exception => e
    #     puts e.message
    #     fail_count += 1
    #   end
    # end
  end

  # 传入姓名或拼音，返回用户
  #
  # ================
  # 参数： string
  def self.find_user(str)
    return [] unless str.present?

    # if /[\d._]/.match(str).present?   # 若包含数字或._, 优先按照email查找
    #   regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
    #   users = Sys::User.find(:all, :conditions => ["users.email LIKE ? ", "%#{str}%"],:limit => 10) # 邮箱 连续
    #   users = Sys::User.find(:all, :conditions => ["users.email REGEXP ? ", regrep_str],:limit => 10) unless users.present? # 邮箱 连续
    # else
    #   if str.length == 1    #若只输入了一个字符
    #     # 短字符中文优先级高
    #     users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "#{str}%"], :limit => 10)  # 当作"姓"的中文字符查
    #     users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "%#{str}%"], :limit => 10) unless users.present? # 当作"姓名"的中文字符查
    #     # 若无结果, 则按拼音的第一个字母查
    #     users = Sys::User.find(:all, :conditions => ["LEFT(users.f_letters ,1) = ?", "#{str}"], :limit => 10) unless users.present?  # 拼音的第一个字母
    #     users = Sys::User.find(:all, :conditions => ["users.f_letters LIKE ? ", "%#{str}%"], :limit => 10) unless users.present?   # 若无, 按首字母某个字母查
    #   else
    #     regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
    #     users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "%#{str}%"], :limit => 10)  # 中文
    #     # 严格查找
    #     users = Sys::User.find(:all, :conditions => ["users.f_letters = ?", "#{str}"], :limit => 10) unless users.present? # 首字母
    #     users = Sys::User.find(:all, :conditions => ["users.family_name = ?", "#{str}"], :limit => 10) unless users.present? # 按姓的拼音查
    #     # 开始匹配
    #     users = Sys::User.find(:all, :conditions => ["users.family_name LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 按姓的拼音查
    #     users = Sys::User.find(:all, :conditions => ["users.f_letters LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 首字母连续
    #     users = Sys::User.find(:all, :conditions => ["users.full_name LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 全拼连续
    #     # REGEXP
    #     users = Sys::User.find(:all, :conditions => ["users.full_name REGEXP ? ", regrep_str],:limit => 10) unless users.present? # 全拼断续
    #     users = Sys::User.find(:all, :conditions => ["users.email REGEXP ? ", regrep_str],:limit => 10) unless users.present?  # 邮箱 断续
    #   end
    # end
    users = Sys::User.all.limit(5)
    return users
  end

  # 登录前检查用户是否存在，及是否允许访问
  # 
  # ping.wang 2013.07.05
  def self.check_user(email, password)
    return nil if !email
    user = where(:email => email).first
    (user.present? && user.allow_access) ? user : nil
  end
end
