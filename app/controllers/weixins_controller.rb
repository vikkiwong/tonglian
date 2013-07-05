# encoding: utf-8
class WeixinsController < ApplicationController
  def index
    render :text => params[:echostr]
  end

  def create
    @user= Sys::User.find_by_weixin_id(params[:xml][:FromUserName])
    #@event = UserEvent.where(["user_id = ? and create_at > ?",@user.id,Time.now - 1.minutes]).order("id desc").limit(1)
    @introduction  = " 您好，我是小优！\n 输入姓名可查询通联\n 如“优众”“youzhong”“yz”\n\n【u】更新联系方式\n【h】获取帮助信息"#;\n[3] 图片推送帮助
    if params[:xml][:MsgType] == "text"
      if @user.present?
        #new_event = UserEvent.new({:user_id => @user.id,:event_type => "text",:content =>params[:xml][:Content]})
        #new_event.save
        if /^[0-9]+$/.match(params[:xml][:Content])
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
             if user.present?
                user.weixin_id = nil
                user.save
             end
          else
            @start = "抱歉，没有找到相关通联信息，请重新查找。\n回复【h】以获取帮助。"
            render "start", :formats => :xml
          end
        elsif ["u","U"].include?(params[:xml][:Content])
          render "update_info", :formats => :xml
        elsif ["?","help","h","帮助","Help","HELP","H","？"].include?(params[:xml][:Content])
          @start = @introduction
          render "start", :formats => :xml
        else
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
      else
        @start = "您尚未验证!"
        render "unregistered_start", :formats => :xml
      end
    elsif params[:xml][:MsgType] == "event"
      if params[:xml][:Event] == "subscribe"
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


  private
  def check_weixin_legality
    array = [WX_TAKEN, params[:timestamp], params[:nonce]].sort
    render :text => "Forbidden", :status => 403 if params[:signature] != Digest::SHA1.hexdigest(array.join)
  end

end
