class Notifier < ActionMailer::Base
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