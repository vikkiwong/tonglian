# encoding: utf-8
class Sys::GroupsController < ApplicationController
  def index
  end

  def my_group
  end

  def create
  	p "---------#{params}-------"
    user = Sys::User.where(:id => session[:id]).first
    group = Sys::Group.new(:user_id => user.id,:name => params[:name],:contact_phone => params[:phone])
    if group.save
      Sys::UserGroup.create(:user_id => user.id,:group_id => group.id)
      redirect_to step_three_sessions_path(:group_id => group.id)
    else
      redirect_to step_two_sessions_path :notice => "圈子创建失败。"
    end
  end
end
