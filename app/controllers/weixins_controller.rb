# encoding: utf-8
class WeixinsController < ApplicationController
  skip_before_filter :login_check

  def index
    render :text => params[:echostr]
  end

  def create
    @user= Sys::User.find_by_weixin_id(params[:xml][:FromUserName])
    if params[:xml][:MsgType] == "text"
      if @user.present?
        if /^[0-9]+$/.match(params[:xml][:Content])
          system_info_action
        elsif ["u","U"].include?(params[:xml][:Content])
          update_user_action
        elsif ["?","help","h","帮助","Help","HELP","H","？"].include?(params[:xml][:Content])
          help_info_action
        else
          search_user_action
        end
      else
        unregistered_action
      end
    elsif params[:xml][:MsgType] == "event"
      event_action
    end
  end


  private
  def check_weixin_legality
    array = [WX_TAKEN, params[:timestamp], params[:nonce]].sort
    render :text => "Forbidden", :status => 403 if params[:signature] != Digest::SHA1.hexdigest(array.join)
  end

  #平台用户统计数据 管理员专用
  #
  # guanzuo.li
  # 2013-07-08
  def system_info_action
    if params[:xml][:Content] == "2408" && @user.role == "manager"
      @start = "[1001] 总用户数\n[1002] 绑定微信用户数"
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1001" && @user.role == "manager"
      users = Sys::User.all
      @start = "总用户数 #{users.size}人 "
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1002" && @user.role == "manager"
      users = Sys::User.where("weixin_id is not null and weixin_id != ''")
      @start = "绑定微信用户数 #{users.size}人 "
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1009" && @user.role == "manager"
      user = Sys::User.find_by_weixin_id(params[:xml][:FromUserName])
      @start = "已解除微信绑定。\n如需重新绑定，"
      if user.present?
        user.weixin_id = nil
        user.save
      end
      render "unbound_start", :formats => :xml
    else
      @start = "抱歉，没有找到相关通联信息，请重新查找。\n回复【h】以获取帮助。"
      render "start", :formats => :xml
    end
  end

  #用户通联信息修改
  #
  #guanzuo.li
  #2013-07-08
  def update_user_action
    render "update_info", :formats => :xml
  end

  #用户帮助信息
  #
  #guanzuo.li
  #2013-07-08
  def help_info_action
    @start = " 您好，我是通联助手！\n 输入姓名可查询通联\n 如“通联”“tonglian”“tl”\n\n【u】更新联系方式\n【h】获取帮助信息"
    render "start", :formats => :xml
  end

  #用户通联信息搜索
  #
  #guanzuo.li
  #2013-07-08
  def search_user_action
    @users = Sys::User.find_user(params[:xml][:Content])
    if @users.present?
      if @users.size == 1
        render "single_address",:formats => :xml
      else
        render "address_list", :formats => :xml
      end
    else
      @start = "抱歉，没有找到相关通联信息，请重新查找。\n回复【h】以获取帮助。"
      render "start", :formats => :xml
    end
  end

  #未注册信息提醒
  #
  #guanzuo.li
  #2013-07-08
  def unregistered_action
    @start = "您尚未验证!"
    render "unregistered_start", :formats => :xml
  end

  #事件类型处理
  #
  #guanzuo.li
  #2013-07-08
  def event_action
    if params[:xml][:Event] == "subscribe"
      @introduction  = " 您好，我是通联助手！\n 输入姓名可查询通联\n 如“通联”“tonglian”“tl”\n\n【u】更新联系方式\n【h】获取帮助信息"
      render "new_user", :formats => :xml
    end
    if params[:xml][:Event] == "unsubscribe"
      user = Sys::User.find_by_weixin_id(params[:xml][:FromUserName])
      if user.present?
        user.weixin_id = nil
        user.save
      end
    end
  end
end