#encoding: utf-8
class SessionsController < ApplicationController
  def create
    #verification = Rails.env == "production" ? User.sign_up(params[:email], params[:password]) : true   # 邮箱验证,若是develop环境则不验证

    #if verification   # 通过邮箱验证
      @user = Sys::User.check_user(params[:email],params[:password])   # 检查数据库是否有该用户
      if @user.present?    # 如果有
        set_session  # 设置session
          # 获得登陆前访问的url
        back_path = session[:back_path]
        back_path = "/" if back_path.blank? || back_path =~ /login/
        session[:back_path] = nil
        redirect_to(back_path)   # 如果有，跳转到登陆前访问的url
      else
        redirect_to("/login", :notice => "抱歉，该邮箱未注册~")
      end
    #else
   #   redirect_to("/login" ,:notice => "用户名或密码错误，请重新登陆")
   # end
  end

  def verification
      p "session_id: #{session[:id]}"
      user = Sys::User.find_by_weixin_id(params[:from_user])
      if user.present?
        redirect_to("/success")
      else
        @from_user = params[:from_user]
     end
  end

  def verify
    #verification = Rails.env == "production" ? User.sign_up(params[:email], params[:password]) : true   # 邮箱验证,若是develop环境则不验证

    #if verification
      user = Sys::User.check_user(params[:email],params[:password])
      if user.present?
        registered_user = Sys::User.find_by_weixin_id(params[:FromUser])
        if registered_user.present?
          redirect_to("/verification?from_user=#{params[:FromUser]}", :notice => "抱歉，此微信号已被绑定!")
        else
          user.weixin_id = params[:FromUser]
          user.save
          %w(id email name role).each {|i| session[i.to_sym] = user[i] if user[i].present? }
          session[:expires_at] = 30.days.from_now
          redirect_to("/success")
        end
      else
        redirect_to("/verification?from_user=#{params[:FromUser]}", :notice => "抱歉，该邮箱未注册!")
      end
    #else
    #  redirect_to("/verification?from_user=#{params[:FromUser]}", :notice => "邮箱验证失败")
    #end
  end

  def success

  end

  def send_verify_mail

  end

  protected
  def set_session
  	%w(id email name role).each {|i| session[i.to_sym] = @user[i] if @user[i].present? }
    session[:expires_at] = 1.month.from_now
  end
end
