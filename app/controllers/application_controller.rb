# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :login_check

  def login_check
    p session
    p session[:id]
    p session[:role]
    if session[:id].blank? || session[:role].blank? 
      if params[:from_user].present?   # 若是带有微信id的请求链接
        @user = Sys::User.find_by_weixin_id(params[:from_user])
        unless @user.present?
          session[:back_path] = request.fullpath
          redirect_to("/login", :notice => '您没有登录，请登录!') and return
        end
        set_session       
      else
        session[:back_path] = request.fullpath
        redirect_to("/login", :notice => '您没有登录，请登录!') and return
      end
    end
  end

  # before_filter方法，检查用户是否是管理员
  #
  # ping.wang 2013.07.09
  def if_manager

    unless ["manager","group_manager"].include?(session[:role])
      redirect_to("/login", :notice => '您没有权限进行此操作！') and return
    end
  end

  protected
  def set_session
      %w(id email name role).each {|i| session[i.to_sym] = @user[i] if @user[i].present? }
      session[:expires_at] = 1.month.from_now
  end
end
