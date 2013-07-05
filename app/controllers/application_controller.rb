# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  def login_check
    if session[:id].blank?
      session[:back_path] = request.fullpath
      redirect_to("/login", :notice => '您没有登录，请登录!') and return
    end
  end
end
