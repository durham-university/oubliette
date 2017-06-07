module Oubliette
  module AbilityBehaviour
    extend ActiveSupport::Concern

    include CanCan::Ability

    def initialize(user)
      set_oubliette_abilities(user)
    end

    def set_oubliette_abilities(user)
      user ||= User.new

      if user.is_admin?
        can :manage, :all
      elsif user.is_api_user?
        can :manage, :all
        can :start_export_job, DurhamRails::BackgroundJobContainer
        can :export, :all
      elsif user.is_editor?
        can [:read,:new,:create,:index], [Oubliette::PreservedFile, Oubliette::FileBatch]
        can [:download], ActiveFedora::File
      elsif user.is_registered?
      else
      end
    end
  end
end
