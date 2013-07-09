# encoding: utf-8
module ApplicationHelper
  #=============== 用户微信消息页面 ==============#
  def wx_str(item)
    case item
      when "email"
        "邮箱"
      when "mobile"
        "手机"
      when "phone"
        "座机"
    end
  end

  def wx_img(item)
    case item
      when "email"
        "email-icon.jpg"
      when "mobile"
        "mobile-icon.jpg"
      when "phone"
        "tel-icon.jpg"
    end
  end

  def is_manager?
    session[:role] == "manager" ? true : false
  end
end
