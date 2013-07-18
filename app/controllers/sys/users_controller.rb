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
    @sys_users = Sys::User.where("email!='admin@email.com'").paginate :page => params[:page]
    #render :layout => 'application'
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

  # GET /sys/users/1/edit
  def edit
  end


  # POST /sys/users
  # POST /sys/users.json
  # 注册用户方法
  def create
    @user = Sys::User.find_by_email(params[:email])
    if @user.present?
      unless @user.role == "member"
        redirect_to(:back, :notice => "此邮箱已注册，请登陆！") and return
      end
      @user.update_attributes(:role => "group_manager", :name => params[:name],:password => params[:password], :active => false)
      Notifier.send_activate_group_manager_mail(@user)
      set_session and redirect_to step2_path
    else
      unless params[:password] == params[:password_confirm]
        redirect_to step1_path, :notice => "密码验证不一致" and return
      end
      @user = Sys::User.create(:email => params[:email], :role => "group_manager",:name => params[:name],:password => params[:password], :active => false)
      Notifier.send_activate_group_manager_mail(@user)
      set_session and redirect_to step2_path
    end
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

  # DELETE /sys/users/1
  # DELETE /sys/users/1.json
  # 
  # ping.wang 2013.07.05 
  def destroy
    @sys_user.destroy
    redirect_to sys_users_url
  end
=begin
  # OPTIMIZE
  # 添加圈子成员
  def import_group_member
    begin
      wrong_line = Sys::User.import_group_users(params[:bunch_users],params[:group_id])
      group = Sys::Group.where(:id => params[:group_id]).first
      if group.active
        Notifier.send_group_invite_mails(group)
        flash[:notice] = "邮箱为" + wrong_line.join(",") + "的用户创建出错了, 请检查！" if wrong_line.present?
        redirect_to sys_group_path(group)
      else
        flash[:notice] = "请先激活管理员权限。"
        render step3_path
      end
    rescue Exception => e
      p e.message
      redirect_to step_three_sessions_path(:group_id => group.id)
    end
  end
=end
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
            redirect_to success_sessions_path(:message => "activate_group_manager")
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

  #发送管理员激活邮件
  def send_activate_mail
    user = Sys::User.where(:id => session[:id]).first
    Notifier.send_activate_group_manager_mail(user) if user.present?
    redirect_to step2_path
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
