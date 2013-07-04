class Sys::UsersController < ApplicationController
  # GET /sys/users
  # GET /sys/users.json
  def index
    @sys_users = Sys::User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sys_users }
    end
  end

  # GET /sys/users/1
  # GET /sys/users/1.json
  def show
    @sys_user = Sys::User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sys_user }
    end
  end

  # GET /sys/users/new
  # GET /sys/users/new.json
  def new
    @sys_user = Sys::User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sys_user }
    end
  end

  # GET /sys/users/1/edit
  def edit
    @sys_user = Sys::User.find(params[:id])
  end

  # POST /sys/users
  # POST /sys/users.json
  def create
    @sys_user = Sys::User.new(params[:sys_user])

    respond_to do |format|
      if @sys_user.save
        format.html { redirect_to @sys_user, notice: 'User was successfully created.' }
        format.json { render json: @sys_user, status: :created, location: @sys_user }
      else
        format.html { render action: "new" }
        format.json { render json: @sys_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sys/users/1
  # PUT /sys/users/1.json
  def update
    @sys_user = Sys::User.find(params[:id])

    respond_to do |format|
      if @sys_user.update_attributes(params[:sys_user])
        format.html { redirect_to @sys_user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sys_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sys/users/1
  # DELETE /sys/users/1.json
  def destroy
    @sys_user = Sys::User.find(params[:id])
    @sys_user.destroy

    respond_to do |format|
      format.html { redirect_to sys_users_url }
      format.json { head :no_content }
    end
  end
end
