# encoding: utf-8
class Sys::UsersController < ApplicationController
  before_filter :find_user, :only => [:show, :edit, :update]

  # GET /sys/users
  # GET /sys/users.json
  def index
    @sys_users = Sys::User.paginate :page => params[:page]
  end

  # GET /sys/users/1
  # GET /sys/users/1.json
  def show
  end

  # GET /sys/users/new
  # GET /sys/users/new.json
  def new
    @sys_user = Sys::User.new
  end

  def bunch_new
  end

  # 批量导入用户
  # ==== 参数格式 ====
  # 邮箱1，姓名1
  # 邮箱2，姓名2
  # ==== Return ====
  # true or false
  # 
  # ping.wang 2013.07.08 修改
  def bunch_create
    bunch_users = params[:bunch_users]
    wrong_line = Sys::User.import_bunch_users(bunch_users)
    flash[:notice] = "邮箱为" + wrong_line.join(",") + "的记录创建出错了, 请检查！" if wrong_line.present?
    redirect_to sys_users_url
  end

  # GET /sys/users/1/edit
  def edit
  end

  # POST /sys/users
  # POST /sys/users.json
  def create
    @sys_user = Sys::User.new(params[:sys_user])

    if @sys_user.save
      redirect_to @sys_user
    else 
      # @sys_user.errors  这里应该显示错误提示
      render action: "new"
    end
  end

  # PUT /sys/users/1
  # PUT /sys/users/1.json
  def update
    @sys_user = Sys::User.find(params[:id])

    if @sys_user.update_attributes(params[:sys_user])
      redirect_to @sys_user
    else
      # @sys_user.errors 这里应该显示错误提示
      render action: "edit" 
    end
  end

  # DELETE /sys/users/1
  # DELETE /sys/users/1.json
  # 软删除用户，将active 设为false
  # 
  # ping.wang 2013.07.05 
  def destroy
    @sys_user = Sys::User.find(params[:id])
    @sys_user.destroy
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
      flash[:notice] = "用户不存在"
      redirect_to sys_users_url
    end
  end
end
