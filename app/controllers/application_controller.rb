# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :login_check

  def login_check
    Rails.logger.debug "*"*30
    Rails.logger.debug params
    Rails.logger.fatal params
    Rails.logger.info params
    if session[:id].blank? || session[:role].blank?
      session[:back_path] = request.fullpath
      redirect_to("/login", :notice => '您没有登录，请登录!') and return
    end
  end

  # before_filter方法，检查用户是否是管理员
  #
  # ping.wang 2013.07.09
  def if_manager
    unless session[:role] == "manager"
      redirect_to("/login", :notice => '您没有权限进行此操作！') and return
    end
  end
end
