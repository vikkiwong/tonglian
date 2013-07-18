# encoding: utf-8
class Sys::GroupsController < ApplicationController
  before_filter :if_member
  before_filter :find_group, :only => [:show, :edit, :update, :destroy]

  def index
    if session[:role] == "manager"
      @sys_groups = Sys::Group.order("created_at DESC").all.paginate :page => params[:page]
    else # group_manager
      @sys_groups = Sys::Group.order("created_at DESC").find_all_by_user_id(session[:id]).paginate :page => params[:page]
    end
  end

  def show
  end

  # step_two的form提交到该方法
  def create
    user = Sys::User.where(:id => session[:id]).first
    group = Sys::Group.new(:user_id => user.id, :name => params[:name],:contact_phone => params[:phone])
    if group.save
      Sys::Group.create_group_picture(group)     #圈子创建成功后生成图片
      Sys::UserGroup.create(:user_id => user.id,:group_id => group.id)
      redirect_to step_three_sessions_path(:group_id => group.id)
    else
      redirect_to step_two_sessions_path :notice => "圈子创建失败。"
    end
  end
  def destroy
      #File.delete("/public/#{@group.group_picture}") if File.file?("/public/#{@group.group_picture}")
      File.delete(@group.group_picture)
      @group.destroy
      redirect_to sys_groups_url
  end

  def edit
  end

  def invitation
    
  end

  # 
  def invite_users
    # 邀请用户方法
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

  def destroy
    @sys_group.destroy
    redirect_to sys_groups_url
  end

  def find_group
    @sys_group = Sys::Group.find_by_id(params[:id])
    unless @sys_group.present? 
      flash[:notice] = "用户不存在！"
      redirect_to sys_groups_url
    end
  end
end
