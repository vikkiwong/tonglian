#encoding: utf-8
class SessionsController < ApplicationController
  skip_before_filter :login_check
  
  # 登陆方法
  #
  # ping.wang 2013.07.05
  def create
    @user = Sys::User.check_user(params[:email])   # 检查数据库是否有该用户，且该用户是否有登陆权限
    redirect_to("/login", :notice => "抱歉，该邮箱没有权限！") and return unless @user.present?

    if @user.password.present? && @user.password == params[:password]
      set_session  # 设置session
      # 跳转到登陆前访问的页面
      back_path = session[:back_path]
      back_path = "/" if back_path.blank? || back_path =~ /login/
      session[:back_path] = nil
      redirect_to(back_path)      
    else
      redirect_to("/login", :notice => "抱歉，密码不正确！")
    end
  end

  # 退出方法,清空session
  # 
  # ping.wang 2013.07.09
  def destroy
    reset_session
    redirect_to("/login")
  end

  def verification
      p "session_id: #{session[:id]}"
      user = Sys::User.find_by_weixin_id(params[:from_user])
      if user.present?
        redirect_to("/sessions/success?message=verified")
      else
        @from_user = params[:from_user]
      end
  end

  def verify
    if /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match(params[:email]).present?
      user = Sys::User.check_user(params[:email])
      if user.present?
        registered_user = Sys::User.find_by_weixin_id(params[:FromUser])
        if registered_user.present?
          redirect_to("/sessions/verification?from_user=#{params[:FromUser]}", :notice => "抱歉，此微信号已被绑定!")
        else
          if user.weixin_id.present?
            redirect_to("/sessions/verification?from_user=#{params[:FromUser]}", :notice => "抱歉，此邮箱已被绑定!")
          else
            Notifier.send_verify_mail(params[:email],params[:FromUser]) if params[:FromUser].present?
            redirect_to success_sessions_path(:message => "send_mail")
          end
        end
      else
        redirect_to("/sessions/verification?from_user=#{params[:FromUser]}", :notice => "抱歉，该邮箱没有绑定权限!")
      end
    else
      redirect_to("/sessions/verification?from_user=#{params[:FromUser]}", :notice => "邮箱格式不正确!")
    end
  end

  def success
    case params[:message]
      when "send_mail"
        @success_message = "已发送验证邮件"
      when "verified"
        @success_message = "成功绑定微信号，进入微信体验通联吧！"
    end
    render :text => @success_message
  end

  #接收验证邮件里的链接
  def mail_verify
    source = Base64.decode64(params[:code])
      if source.present?
        source_arr = source.split("&")
        email = source_arr[0]
        weixin_id = source_arr[1]
        user = Sys::User.check_user(email)
        user.weixin_id = weixin_id
        user.save
        %w(id email name role).each {|i| session[i.to_sym] = user[i] if user[i].present? }
        session[:expires_at] = 30.days.from_now
        redirect_to("/sessions/success?message=verified")
      else
        render :text => "fail"
      end
  end
  
  protected
  def set_session
      %w(id email name role).each {|i| session[i.to_sym] = @user[i] if @user[i].present? }
      session[:expires_at] = 1.month.from_now
  end
end
