# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  #before_filter :login_check

  def login_check
    if session[:id].blank?
      session[:back_path] = request.fullpath
      redirect_to("/login", :notice => '您没有登录，请登录!') and return
    end
  end

  private
  #cancan插件初始化用户权限方法
  #
  # zhanghong
  # 2012-07-11
  def current_ability
    begin
      @current_user = @current_user || User.find(session[:id])
      @current_ability ||= Ability.new(@current_user)
    rescue
      redirect_to("/login") and return
    end
  end
end
