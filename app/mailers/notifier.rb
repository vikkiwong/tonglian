#encoding: utf-8
class Notifier < ActionMailer::Base

  self.smtp_settings = {:address => EMAIL_CONFIG["notice_sender"]["address"],
      :domain => EMAIL_CONFIG["notice_sender"]["domain"],
      :enable_starttls_auto => EMAIL_CONFIG["notice_sender"]["enable_starttls_auto"],
      :port => EMAIL_CONFIG["notice_sender"]["port"],
      :user_name => EMAIL_CONFIG["notice_sender"]["user_name"],
      :password => EMAIL_CONFIG["notice_sender"]["password"],
      :authentication => EMAIL_CONFIG["notice_sender"]["authentication"]
    }
  self.default(
    :charset => "UTF-8",
    :content_transfer_encoding => '7bit',
    :from => "#{EMAIL_CONFIG["notice_sender"]["name"]} <#{EMAIL_CONFIG["notice_sender"]["email"]}>"
  )

  def send_verify_mail(email,weixin_id)
    user = Sys::User.where(:email => email).first
    @name = user.name
    code_str = email + "&" + weixin_id + "&" + Time.now.strftime('%Y-%m-%d %H:%M:%S').to_s #email,weixin_id必存在
    @code = Base64.encode64(code_str)
    mail(:to => email, :subject => "绑定验证").deliver!
  end

  #管理员申请回复邮件
  #
  #guanzuo.li
  #2013.07.16
  def send_apply_for_admin_mail(email,code)
    @code = code
    mail(:to => email, :subject => "管理员申请").deliver!
  end

  #管理员及其创建的圈子激活邮件
  def send_activate_group_manager_mail(user)
    @name = user.name
    code_str = user.id.to_s + "&" + Time.now.strftime('%Y-%m-%d %H:%M:%S').to_s
    @code = Base64.encode64(code_str)
    mail(:to => user.email, :subject => "微信圈管理员激活邮件").deliver!
  end


  #圈成员邀请邮件
  #
  #guanzuo.li
  #2013.07.16
  def send_group_invite_mails(group)
    group.users.each do |user|
      next if user.id == group.user_id
      mail(:to => user.email, :subject => "邀请您加入#{group.name}").deliver!
    end
  end

  def send_mail(params = {})
    @mail_body = params[:mail_body]
    mail(:subject => params[:subject],
         :to =>"vikkiwong2012@gmail.com",
         :from => 'valleywangping@163.com',
         :date => params[:date],
         :body => @mail_body
    )
  end
end