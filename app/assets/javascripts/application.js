// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

// 设置当前页面对应的导航栏高亮
function settingMenuClass(){
		var act_name = $("label#current_action_name").html();
	  var ctrl_name = $("label#current_controller_name").html();
	  var li_id = "";
	  if(ctrl_name == "sys/groups"){
	    li_id = "groups";
	  }else if(ctrl_name == "feedbacks"){
	  	li_id = "feedbacks"
	  }else{
	    li_id = "none";
	  };
	  $("li#"+li_id).addClass("active");
	  $("li#"+li_id).siblings().removeClass("active");
};

$(document).ready(function() {
	settingMenuClass();
});