# encoding: utf-8
class Sys::GroupsController < ApplicationController
  before_filter :if_manager, :only => :index

  def index
    @group = Sys::Group.all
  end

  def my_group
    @group = Sys::Group.find_by_user_id(session[:id])
  end

  def create
    user = Sys::User.where(:id => session[:id]).first
    group = Sys::Group.new(:user_id => user.id,:name => params[:name])
    if group.save
      Sys::UserGroup.create(:user_id => user.id,:group_id => group.id)
      redirect_to step_three_sessions_path(:group_id => group.id)
    else
      redirect_to step_two_sessions_path :notice => "圈子创建失败。"
    end
  end
end
