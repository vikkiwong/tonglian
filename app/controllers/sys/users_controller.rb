# encoding: utf-8
class Sys::UsersController < ApplicationController
  #before_filter :login_check
  before_filter :find_user, :only => [:show, :edit, :update]

  # GET /sys/users
  # GET /sys/users.json
  def index
    @sys_users = Sys::User.all
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

  def multi_users
  end

  def import_users
    # data = params[:users_info]
    # Sys::User.import_users(data)
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
      # @sys_user.errors
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
      # @sys_user.errors
      render action: "edit" 
    end
  end

  # DELETE /sys/users/1
  # DELETE /sys/users/1.json
  # 软删除用户，将active 设为false
  def destroy
    @sys_user = Sys::User.find(params[:id])
    @sys_user.update_attributes(:active => false)
    redirect_to sys_users_url
  end

  # before_filter，检查用户是否存在
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
