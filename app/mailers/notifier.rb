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
    code_str = email + "&" + weixin_id #email,weixin_id必存在
    @code = Base64.encode64(code_str)
    mail(:to => email, :subject => "绑定验证").deliver!
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