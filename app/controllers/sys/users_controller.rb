# encoding: utf-8
class Sys::UsersController < ApplicationController
  skip_before_filter :login_check, :only => [:new, :create, :activate_group_manager]
  before_filter :find_user, :only => [:show, :edit, :update, :destroy,:group_create]
  before_filter :if_manager, :only => [:index, :bunch_new, :bunch_create, :destroy, :group_new, :group_create]
  before_filter :if_can_manage, :only => [:edit, :update]

  # GET /sys/users
  # GET /sys/users.json
  # 改页面只允许管理员角色查看
  #
  # ping.wang 2013.07.09
  def index
    # @sys_users = Sys::User.where("email!='admin@email.com'").paginate :page => params[:page]
    # render :layout => 'application'
  end

  # GET /sys/users/1
  # GET /sys/users/1.json
  def show
    flash[:notice] = @sys_user.errors.collect{|attr,error| error}.join(" ") if @sys_user.errors.any?
  end

  # GET /sys/users/new
  # GET /sys/users/new.json
  def new
    @sys_user = Sys::User.new
  end

  # POST /sys/users
  # POST /sys/users.json
  # 注册账号
  def create
    unless params[:sys_user].present? && params[:sys_user][:password].present? && params[:sys_user][:password] == params[:password_confirm]
      flash[:notice] = "密码验证不一致" and render :new and return
    end

    @sys_user = Sys::User.find_by_email_and_is_valid(params[:sys_user][:email], true)
    if @sys_user.present?
      if @sys_user.role == "member"
        @sys_user.update_attributes(:role => "group_manager", :name => params[:sys_user][:name], :password => params[:sys_user][:password], :active => false)
        %w(id email name role).each {|i| session[i.to_sym] = @sys_user[i] if @sys_user[i].present? }
        redirect_to need_active_sys_users_path   # 跳转到激活页     
      else
        redirect_to(:back, :notice => "此邮箱已注册，请登陆！") and return
      end
    else
      @sys_user = Sys::User.new(params[:sys_user])  
      @sys_user.active = false 
      @sys_user.role = "group_manager"
      if @sys_user.save
        #set_session
        %w(id email name role).each {|i| session[i.to_sym] = @sys_user[i] if @sys_user[i].present? }
        redirect_to need_active_sys_users_path
      end
    end
  end

  # GET /sys/users/1/edit
  def edit
  end

  # PUT /sys/users/1
  # PUT /sys/users/1.json
  def update
    if @sys_user.update_attributes(params[:sys_user])
      redirect_to @sys_user
    else
      flash[:notice] = @sys_user.errors.collect{|attr,error| error}.join(" ") if @sys_user.errors.any?
      render action: "edit"
    end
  end

  # GET    /sys/users/need_active(.:format)
  # 成功注册账号后，跳转到激活页面, 页面提供发送激活邮件按钮
  def need_active
    sys_user = Sys::User.where(:id => session[:id]).first
    @active_flag = sys_user.active   # 标志当前账号是否激活
  end

  # GET    /sys/users/send_activate_mail(.:format)
  # 发送管理员激活邮件
  def send_activate_mail
    sys_user = Sys::User.where(:id => session[:id]).first
    Notifier.send_activate_group_manager_mail(sys_user) if sys_user.present?
    redirect_to active_mail_sended_sys_users_path
  end

  # GET    /sys/users/active_mail_sended(.:format)
  # 邮件发送后的跳转页面，提示邮件已发送，请登陆邮箱查看
  def active_mail_sended
    sys_user = Sys::User.where(:id => session[:id]).first
    @email = sys_user.email
  end

  #接收圈子管理员激活邮件,激活管理员及其创建圈子使用权限
  def activate_group_manager
    source = Base64.decode64(params[:code])
      if source.present?
        source_arr = source.split("&")
        user_id = source_arr[0]
        send_time = Time.parse(source_arr[1])
        if send_time > Time.now - 1.days
          begin
            Sys::User.update(user_id,:active => true)
            Sys::Group.update_all(:active => true,:user_id => user_id)
            #is_actived_sys_users
            #redirect_to success_sessions_path(:message => "activate_group_manager")
            redirect_to is_actived_sys_users_path
          rescue Exception => e
            p e.message
            render :text => "激活失败" + e.message
          end
        else
          render :text => "链接过期"
        end
      else
        render :text => "Fail"
      end
  end

  # 已激活
  def is_actived
  end

  # DELETE /sys/users/1
  # DELETE /sys/users/1.json
  # 
  # ping.wang 2013.07.05 
  def destroy
    @sys_user.update_attribute(:is_valid, false)
    redirect_to sys_users_url
  end

  # before_filter方法，检查用户是否存在
  # ==== params ====
  # 用户ID(:id)
  # 
  # ping.wang 2013.07.05
  def find_user
    @sys_user = Sys::User.find_by_id(params[:id])
    unless @sys_user.present? 
      flash[:notice] = "用户不存在！"
      redirect_to sys_users_url
    end
  end

  # before_filter方法，检查用户是否有权限操作
  # (如果是管理员或者操作对象是自己则有权限)
  # 
  # ping.wang 2013.07.09
  def if_can_manage
    unless @sys_user.id == session[:id] || session[:role] == "manager"
      flash[:notice] = "没有权限进行此操作！"
      redirect_to :back      
    end
  end
end
