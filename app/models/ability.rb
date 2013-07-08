class Ability
	include CanCan::Ability

	def initialize(user)
		@current_user = user
    if @current_user.role.present?
      send(@current_user.role)
    else
      member
    end
	end

	def member
		can :read, Sys::User
	end

	def manager
	end
end