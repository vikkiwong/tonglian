class Sys::User < ActiveRecord::Base
  attr_accessible :active, :allow_access, :blog, :email, :id, :mobile, :name, :phone, :qq, :role, :sex, :weibo, :weixin

  def self.import_users(data)
    success_count = 0
    fail_count = 0
    data.strip.gsub(" ", "").gsub("\r","").split("\n").each do |line|
      value = line.split(",")
      sql_str="insert into sys_users (name,email) values ('#{value[0]}','#{value[1]}')"
      begin
        Sys::User.connection.execute(sql_str)
        success_count += 1
      rescue Exception => e
        puts e.message
        fail_count += 1
      end
    end

  end

   # 传入姓名或拼音，返回用户
  #
  # ================
  # 参数： string
  # 返回： 用户数组 和 message_too_less 标志
  # 程广义  程  广 义 程广  广义  cgy chengguangyi  guangyi cheng  guangyi.chen
  # 修改 搜索分优先级 由高到低 中文 拼音（首字母 - 连续的字母 - 间断的字母) 邮箱(连续字母-间断字母)
  # 若含有符号或者数字，优先按照邮箱搜索 如无结果，忽略字母或数字，中文 按拼音搜索
  def self.find_user(str)
    return [] unless str.present?

    if /[\d._]/.match(str).present?   # 若包含数字或._, 优先按照email查找
      regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
      users = Sys::User.find(:all, :conditions => ["users.email LIKE ? ", "%#{str}%"],:limit => 10) # 邮箱 连续
      users = Sys::User.find(:all, :conditions => ["users.email REGEXP ? ", regrep_str],:limit => 10) unless users.present? # 邮箱 连续
    else
      if str.length == 1    #若只输入了一个字符
        # 短字符中文优先级高
        users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "#{str}%"], :limit => 10)  # 当作"姓"的中文字符查
        users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "%#{str}%"], :limit => 10) unless users.present? # 当作"姓名"的中文字符查
        # 若无结果, 则按拼音的第一个字母查
        users = Sys::User.find(:all, :conditions => ["LEFT(users.f_letters ,1) = ?", "#{str}"], :limit => 10) unless users.present?  # 拼音的第一个字母
        users = Sys::User.find(:all, :conditions => ["users.f_letters LIKE ? ", "%#{str}%"], :limit => 10) unless users.present?   # 若无, 按首字母某个字母查
      else
        regrep_str = ".*" + str.scan(/\w/).join(".*") + ".*"
        users = Sys::User.find(:all, :conditions => ["users.name LIKE ? ", "%#{str}%"], :limit => 10)  # 中文
        # 严格查找
        users = Sys::User.find(:all, :conditions => ["users.f_letters = ?", "#{str}"], :limit => 10) unless users.present? # 首字母
        users = Sys::User.find(:all, :conditions => ["users.family_name = ?", "#{str}"], :limit => 10) unless users.present? # 按姓的拼音查
        # 开始匹配
        users = Sys::User.find(:all, :conditions => ["users.family_name LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 按姓的拼音查
        users = Sys::User.find(:all, :conditions => ["users.f_letters LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 首字母连续
        users = Sys::User.find(:all, :conditions => ["users.full_name LIKE ?", "%#{str}%"], :limit => 10) unless users.present? # 全拼连续
        # REGEXP
        users = Sys::User.find(:all, :conditions => ["users.full_name REGEXP ? ", regrep_str],:limit => 10) unless users.present? # 全拼断续
        users = Sys::User.find(:all, :conditions => ["users.email REGEXP ? ", regrep_str],:limit => 10) unless users.present?  # 邮箱 断续
      end
    end

    return users
  end
end
