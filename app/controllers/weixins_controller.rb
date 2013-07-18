# encoding: utf-8
class WeixinsController < ApplicationController
  skip_before_filter :login_check

  def index
    render :text => params[:echostr]
  end

  def create
    @user= Sys::User.find_by_weixin_id(params[:xml][:FromUserName])
    if params[:xml][:MsgType] == "text"
      if params[:xml][:Content] == "apply"
        apply_for_admin_action
      elsif @user.present?
        if /^[0-9]+$/.match(params[:xml][:Content])
          system_info_action
        elsif /^(jy|建议)/i.match(params[:xml][:Content])
          feed_back_message = $'
          feed_back_action(feed_back_message)
        elsif ["u","U"].include?(params[:xml][:Content])
          update_user_action
        elsif ["?","help","h","帮助","Help","HELP","H","？"].include?(params[:xml][:Content])
          help_info_action(params[:xml][:FromUserName])
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
      @start = "[1001] 总用户数\n[1002] 绑定微信用户数\n[1003] 最近10条反馈"
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1001" && @user.role == "manager"
      users = Sys::User.all
      @start = "总用户数 #{users.size}人 "
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1002" && @user.role == "manager"
      users = Sys::User.where("weixin_id is not null and weixin_id != ''")
      @start = "绑定微信用户数 #{users.size}人 "
      render "start", :formats => :xml
    elsif params[:xml][:Content] == "1003" && @user.role == "manager"
      @feed_backs = Feedback.last(10)
      if @feed_backs.present?
        render "feedback_list", :formats => :xml
      else
        @start = "无反馈信息"
        render "start", :formats => :xml
      end
    elsif params[:xml][:Content] == "10000" && @user.role == "manager"
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

  #用户反馈信息
  #
  #guanzuo.li
  #2013-07-11
  def feed_back_action(message)
    begin
      if message.length < 5  # "message不可能为nil 可能为‘’"
        @start = "您的建议太短了，请重新编辑。"
      else
        Feedback.create(:email => @user.email,:user_id => @user.id,:message => message)
        @start = "建议已保存，谢谢您的关注！"
      end
    rescue Exception => e
      p e.message
      @start = "提交失败。"
    end
    render "start", :formats => :xml
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
  def help_info_action(from_user)
    @start = "您好，我是通联助手!
想建立一个圈子，和好友方便的联系?<a href='http://#{SITE_DOMAIN}/sessions/apply_for_admin?from_user=#{from_user}'>进入这里申请成为管理员</a>!
已经加入圈子了？<a href='http://<%=SITE_DOMAIN%>/sessions/verification?from_user=#{from_user}'>进入这里验证邮箱，体验微信通联</a>!
已经验证邮箱？那就快快体验微通联吧!
输入姓名或拼音首字母即可查询联系方式!
回复u更新自己的联系方式!
回复jy+文字向我们提建议!
回复h查看本条帮助信息!"
    render "start", :formats => :xml
  end

  #管理员申请
  #
  #guanzuo.li
  #2013-07-16
  def apply_for_admin_action
    render "apply_for_admin"
  end

  #用户通联信息搜索
  #
  #guanzuo.li
  #2013-07-08
  def search_user_action
    @users = Sys::User.find_user(params[:xml][:Content],@user)
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
      @introduction  = " 您好，我是通联助手！\n 输入姓名可查询通联\n 如“通联”“tonglian”“tl”\n\n【u】更新联系方式\n【h】获取帮助信息\n【jy+文字】向我们提建议"
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