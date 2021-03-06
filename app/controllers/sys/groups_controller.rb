# encoding: utf-8
class Sys::GroupsController < ApplicationController
  before_filter :if_member
  before_filter :find_group, :only => [:show, :edit, :update, :destroy, :invitation, :invite_users]
  skip_before_filter :login_check, :only => :create_group_user

  def index
    if session[:role] == "manager"
      @sys_groups = Sys::Group.is_valided.ordered.paginate :page => params[:page]
    else
      @sys_groups = Sys::Group.where(:user_id => session[:id]).is_valided.ordered.paginate :page => params[:page]
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
      flash[:notice] = "圈子名称和联系方式都不能为空"
      render :new and return
    end
    user = Sys::User.where(:id => session[:id]).first
    group = Sys::Group.new(:user_id => user.id, :name => params[:name],:contact_phone => params[:phone], :active => user.active)
    if group.save
      Sys::Group.create_group_picture(group)     #圈子创建成功后生成图片
      Sys::UserGroup.find_or_create_by_user_id_and_group_id(:user_id => user.id, :group_id => group.id)
      redirect_to invitation_sys_group_path(group)
    else
      @active_flag = user.active
      flash[:notice] = group.errors.collect {|attr,error| error}.join("\n")
      render :new
    end
  end

  def edit
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

  #添加用户
  def invitation
    user = Sys::User.where(:id => session[:id]).first
    @active_flag = user.active  # 标志当前登陆用户账号是否激活
  end

  # 邀请用户方法
  def invite_users
    begin
      if @sys_group.active
        wrong_line,success_count = Sys::User.import_group_users(params[:bunch_users], @sys_group)  # 导入方法需要修改
        if wrong_line.present?
          flash[:notice] = "成功发送#{success_count}封邀请,邮箱为" + wrong_line.join(",") + "的用户邀请失败。"
        else
          flash[:notice] = "成功发送#{success_count}封邀请"
        end
        redirect_to sys_group_path(@sys_group)
      else
        flash[:notice] = "您需要激活账号才能邀请好友~"
        render :invitation
      end
    rescue Exception => e
      p e.message
      redirect_to invitation_sys_group_path(@sys_group)
    end
  end

  #接收邀请用户邮件中的同意链接
  #
  #guanzuo.li
  #2013.07.24 edit
  def create_group_user
    if params[:code].present?
      source = Base64.decode64(params[:code])
      group_id,user_id,send_time = Sys::Group.analyze_source(source)
      @group = Sys::Group.find(group_id)
      @user = Sys::User.find(user_id)
      if @user.present?
        if send_time > Time.now - 1.days
          begin
            group_user = Sys::UserGroup.find_or_initialize_by_user_id_and_group_id(user_id,group_id)
            group_user.save if group_user.new_record?
            render "group_user_added"
          rescue Exception => e
            p e.message
            @failed_message = e.message
          end
        else
          @failed_message = "邀请邮件过期,新邮件已发送。"
          Notifier.send_group_invite_mails(@user,@group) rescue @failed_message = "邀请邮件过期。"
        end
      else
        @failed_message = "用户已被删除。"
      end
    else
      @failed_message = "标识数据丢失。"
    end
    render "add_group_user_failed" if @failed_message.present?
  end

  # DELETE /sys/groups/:id(.:format)
  def destroy
    File.delete("#{Rails.root}/public#{@sys_group.group_picture}")  if File.exist?("#{Rails.root}/public#{@sys_group.group_picture}")
    @sys_group.update_attribute(:is_valid, false)
    redirect_to sys_groups_url
  end

  #删除圈子中的成员
  #
  #wangyang.shen 2013.07.18
  def destroy_user_group
    if params[:group_id].present? && params[:user_id].present?
      if params[:user_id].to_i != session[:id].to_i
        group_id = params[:group_id]
        user_id = params[:user_id]
        Sys::UserGroup.where("user_id = #{user_id} and group_id = #{group_id}").first.destroy
        Sys::User.reset_invited_records(user_id,group_id)
      end
    end
    redirect_to sys_group_url(@sys_group = Sys::Group.find_by_id(group_id))
  end

  # before_filter方法，检查用户是否有权限操作
  # (如果是管理员或者操作对象是自己则有权限)
  # 
  # ping.wang 2013.07.18
  def find_group
    @sys_group = Sys::Group.find_by_id(params[:id])
    unless @sys_group.present?  && @sys_group.user_id == session[:id] || session[:role] == "manager"
      flash[:notice] = "圈子不存在！"
      redirect_to sys_groups_url
    end
  end
end
