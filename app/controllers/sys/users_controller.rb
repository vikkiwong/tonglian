# encoding: utf-8
class Sys::UsersController < ApplicationController
  skip_before_filter :login_check, :only => [:new, :create]
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
    # @sys_user = Sys::User.new(params[:sys_user])
    # @sys_user.role = "member"

    # if @sys_user.save
    #   redirect_to @sys_user
    # else 
    #   flash[:notice] = @sys_user.errors.collect{|attr,error| error}.join(" ") if @sys_user.errors.any?
    #   render action: "new"
    # end
    @user = Sys::User.find_by_email(params[:email])
    if @user.present?
      unless @user.role == "member"
        redirect_to(:back, :notice => "此邮箱已注册，请登陆！") and return
      end
      @user.update_attributes(:role => "group_manager", :name => params[:name],:password => params[:password], :active => false)
      # 这里需要发送一封发送激活邮件, 点击激活邮件中的链接后，更新active值
      set_session and redirect_to step2_path
    else
      unless params[:password] == params[:password_confirm]
        redirect_to step_one_sessions_path, :notice => "密码验证不一致" and return
      end
      @user = Sys::User.create(:email => params[:email], :role => "group_manager",:name => params[:name],:password => params[:password])
      # 这里需要发送一封发送激活邮件, 点击激活邮件中的链接后，更新active值
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

  # OPTIMIZE
  # 添加圈子成员
  def import_group_member
    begin
      wrong_line = Sys::User.import_group_users(params[:bunch_users],params[:group_id])
      group = Sys::Group.where(:id => params[:group_id]).first
      Notifier.send_group_invite_mails(group)
      flash[:notice] = "邮箱为" + wrong_line.join(",") + "的用户创建出错了, 请检查！" if wrong_line.present?
      redirect_to sys_group_path(group)
    rescue Exception => e
      p e.message
      redirect_to step_three_sessions_path(:group_id => group.id)
    end
  end

=begin
  # GET /sys/users/bunch_new(.:format) 
  # 批量创建用户
  # 
  # ping.wang 2013.07.08
  def bunch_new
  end

  # 批量导入用户
  # ==== 参数格式 ====
  # 邮箱1，姓名1
  # 邮箱2，姓名2
  # 
  # ping.wang 2013.07.08 修改
  def bunch_create
    bunch_users = params[:bunch_users]
    wrong_line = Sys::User.import_bunch_users(bunch_users)
    flash[:notice] = "邮箱为" + wrong_line.join(",") + "的用户创建出错了, 请检查！" if wrong_line.present?
    redirect_to sys_users_url
  end

  # GET  /sys/users/group_new(.:format)
  # 项目初始化页面
  # 
  # ping.wang 2013.07.16
  def group_new

    @sys_user = Sys::User.find_by_id(session[:id])
    @group = Sys::Group.new
    p @sys_user
  end

  # POST   /sys/users/group_create(.:format)
  # 项目初始化方法：修改用户密码，创建group，创建group 用户，给group用户发送邀请邮件
  def group_create
    p "---------#{params}------------------"
    if params[:password].present?
      if params[:password] != params[:password_confirmation]
        redirect_to group_new_sys_users_path, :notice => "密码验证不一致"
      else
        @sys_user.password = params[:password]
        @sys_user.name = params[:name]
        @sys_user.save
      end
    end
    group = Sys::Group.new(:user_id => @sys_user.id,:name => params[:sys_group][:name])
    group.save
    Sys::UserGroup.create(:user_id => @sys_user.id,:group_id => group.id)
    wrong_line = Sys::User.import_group_users(params[:bunch_users],group.id)
    Notifier.send_group_invite_mails(group)
    flash[:notice] = "邮箱为" + wrong_line.join(",") + "的用户创建出错了, 请检查！" if wrong_line.present?
    render :text => "success"
  end

  #添加圈子成员页面
  def group_member_info
      @group_id = params[:group_id]
  end
=end


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
