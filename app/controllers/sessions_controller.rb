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

  # GET    /sessions/apply_for_admin(.:format)
  # 申请管理员页面
  #
  # params :from_user => 微信标识
  # ping.wang  2013.07.16
  def apply_for_admin
    @from_user = params[:from_user]
  end

  # POST   /sessions/apply(.:format)
  # 创建管理员用户
  def apply
    p "---------#{params}-------------"
    elder_admin = Sys::User.where(:email => params[:email],:role => "admin").first
    if elder_admin.present?
      redirect_to :back, :notice => "此邮箱已成为圈主"
    else
      rand_num = 100000 + rand(100000)
      code = Base64.encode64(rand_num.to_s)
      begin
        Sys::User.create(:email => params[:email], :role => "admin", :password => code ,:weixin_id => params[:FromUser])
        Notifier.send_apply_for_admin_mail(params[:email],code)
        redirect_to success_sessions_path(:message => "send_application_mail")
      rescue Exception => e
        p e.message
        redirect_to :back, :notice => "申请失败"
      end
    end
    # 在这里创建管理员用户，并发送包含临时密码的邮件
  end

  # 用户邮箱验证页面进入方法
  #
  # params :from_user => 微信标识
  # guanzuo.li
  # 2013.07.10
  def verification
    user = Sys::User.find_by_weixin_id(params[:from_user])
    if user.present?
      redirect_to("/sessions/success?message=verified")
    else
      @from_user = params[:from_user]
    end
  end

  # 邮箱验证方法
  # 验证顺序：邮箱格式是否正确 => 邮箱是否在白名单（管理员上传用户名单）内 => 用户微信标识是否已存在 => 邮箱是否已存在
  # 验证通过：发送验证邮件
  # params :email => 邮件 :FromUser => 微信标识
  #
  # guanzuo.li
  # 2013.07.10
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

  # 邮箱验证和邮箱绑定成功反馈页面
  #
  # params :message => 反馈类型
  # guanzuo.li
  # 2013.07.10
  def success
    case params[:message]
      when "send_mail"
        @head = "验证邮件发送-微信通联"
        @success_message = "已发送验证邮件"
      when "send_application_mail"
        @head = "申请邮件发送-微信通联"
        @success_message = "已成功发送邮件，请查看邮箱"
      when "verified"
        @head = "验证成功-微信通联"
        @success_message = "成功绑定微信号，进入微信体验通联吧！"
    end
  end

  # 接收验证邮件里的链接，绑定验证邮箱与用户微信标识
  #
  # params :code => 邮箱,微信标识,时间加密字符串
  # guanzuo.li
  # 2013.07.10
  def mail_verify
    source = Base64.decode64(params[:code])
      if source.present?
        source_arr = source.split("&")
        email = source_arr[0]
        weixin_id = source_arr[1]
        send_time = Time.parse(source_arr[2])
        p send_time
        if send_time > Time.now - 1.days
          user = Sys::User.check_user(email)
          user.weixin_id = weixin_id
          user.save
          redirect_to("/sessions/success?message=verified")
        else
          render :text => "链接过期"
        end
      else
        render :text => "Fail"
      end
  end
  
  protected
  def set_session
      %w(id email name role).each {|i| session[i.to_sym] = @user[i] if @user[i].present? }
      session[:expires_at] = 1.month.from_now
  end
end
