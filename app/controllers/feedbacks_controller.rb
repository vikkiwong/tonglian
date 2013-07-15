# encoding: utf-8
class FeedbacksController < ApplicationController
	before_filter :if_manager
	
	def index
		@feedbacks = Feedback.ordered.releated_find.paginate :page => params[:page]
	end
end
