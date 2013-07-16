Sys::User.all.each do|user|
 Sys::User.create_message_picture(user)
end