# encoding: utf-8
class Sys::GroupsController < ApplicationController
  before_filter :if_member
  before_filter :find_group, :only => [:show, :edit, :update, :destroy, :invitation]

  def index
    if session[:role] == "manager"
      @sys_groups = Sys::Group.order("created_at DESC").all.paginate :page => params[:page]
    else # group_manager
      @sys_groups = Sys::Group.order("created_at DESC").find_all_by_user_id(session[:id]).paginate :page => params[:page]
    end
  end

  def show
  end

  def new
    user = Sys::User.where(:id => session[:id]).first
    @active_flag = user.active  # 标志当前登陆用户账号是否激活
  end

  # step_two的form提交到该方法
  def create
    unless params[:name].present? && params[:phone].present?
      render :new,  :notice => "圈子名称和圈子名称都不能为空" and return
    end

    user = Sys::User.where(:id => session[:id]).first
    group = Sys::Group.new(:user_id => user.id, :name => params[:name],:contact_phone => params[:phone], :active => user.active)
    if group.save
      Sys::Group.create_group_picture(group)     #圈子创建成功后生成图片
      Sys::UserGroup.find_or_create_by_user_id_and_group_id(:user_id => user.id, :group_id => group.id)
      redirect_to invitation_sys_group_path(group)
    else
      flash[:notice] = group.errors.collect {|attr,error| error}.join("\n")
      render :new
    end
  end

  def destroy
    File.delete("#{Rails.root}/public#{@sys_group.group_picture}")  if File.exist?("#{Rails.root}/public#{@sys_group.group_picture}")
    @sys_group.destroy
    redirect_to sys_groups_url
  end

  #删除圈子中的成员
  def destroy_user_group
    if params[:group_id].present? && params[:user_id].present?
      if params[:user_id].to_i != session[:id].to_i
        group_id = params[:group_id]
        user_id = params[:user_id]
        Sys::UserGroup.where("user_id = #{user_id} and group_id = #{group_id}").first.destroy
      end
    end
    redirect_to sys_group_url(@sys_group = Sys::Group.find_by_id(group_id))
  end

  def edit
  end

  #添加用户
  def invitation
    user = Sys::User.where(:id => session[:id]).first
    @active_flag = user.active  # 标志当前登陆用户账号是否激活
  end

  # 邀请用户方法
  def invite_users
    begin
      wrong_line = Sys::User.import_group_users(params[:bunch_users],params[:id])
      group = Sys::Group.where(:id => params[:id]).first
      Notifier.send_group_invite_mails(group)
      flash[:notice] = "邮箱为" + wrong_line.join(",") + "的用户创建出错了, 请检查！" if wrong_line.present?
      redirect_to sys_group_path(group)
    rescue Exception => e
      p e.message
      redirect_to invitation_sys_group_path(group)
    end

  end

  def update
    if @sys_group.update_attributes(params[:sys_group])
      Sys::Group.create_group_picture(@sys_group)      #圈子修改成功后生成图片
      redirect_to @sys_group
    else
      flash[:notice] = @sys_group.errors.collect{|attr,error| error}.join(" ") if @sys_group.errors.any?
      render action: "edit"
    end
  end

  def find_group
    @sys_group = Sys::Group.find_by_id(params[:id])
    unless @sys_group.present? 
      flash[:notice] = "圈子不存在！"
      redirect_to sys_groups_url
    end
  end
end
