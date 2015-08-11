class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
      # alias_action :create, :read, :update, :destroy, :to => :crud
      alias_action :delete, :destroy, :to => :update_destroy
      alias_action :show_bank, :edit_bank, :to => :bank # 用于单位管理的维护开户银行
      alias_action :show, :only_show_logs, :only_show_info, :index , :to => :read #用于用户管理

      user ||= User.new # guest user (not logged in)
      user.can_option_hash.each do |k,v|
        can v.map{ |e| e.to_sym }, k.constantize
      end
      # if user.admin?
      #   can :manage, :all
      # else
      #   user.permissions.each do |p|
      #   begin
      #     subject = begin
      #                 # RESTful Controllers
      #                 p.subject.camelize.constantize
      #               rescue
      #                 # Non RESTful Controllers
      #                 p.subject.underscore.to_sym
      #               end
      #     can p.action.to_sym, subject
      #   rescue => e
      #     Rails.logger.info "cancancan异常---------#{e}"
      #     Rails.logger.info "cancancan对象#{subject}"
      #   end
      # end
      # end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/bryanrite/cancancan/wiki/Defining-Abilities
    
  end
end
