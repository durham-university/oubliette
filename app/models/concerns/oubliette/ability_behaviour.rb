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
# These actions should be done by impersonating another user which can perform them
#        can :call, Jobduct::Binding, binding_key: ['export', 'ingest_file', 'ingest_batch', 'create_batch', 'fixity_single', 'characterisation']
#        can :call, Jobduct::Callback
#        can [:show, :tunnel_callback], [Jobduct::Channel, Jobduct::Callback]
#        can :export, :all
        can :impersonate, User
      elsif user.is_editor?
        can [:index, :create, :new], [Oubliette::PreservedFile, Oubliette::FileBatch]
        can [:read], [Oubliette::PreservedFile, Oubliette::FileBatch, DurhamRails::BackgroundJobContainer] do |item| item.can_read?(user) end
        can [:update, :destroy], [Oubliette::PreservedFile, Oubliette::FileBatch] do |item| item.can_edit?(user) end
        can [:create], [Oubliette::PreservedFile, Oubliette::FileBatch]
        can [:download], [Oubliette::PreservedFile] do |item| item.can_read?(user) end
          
        can :call, Jobduct::Binding, binding_key: ['export', 'ingest_file', 'ingest_batch', 'create_batch', 'fixity_single', 'characterisation']

        can [:show, :index, :destroy, :tunnel_callback, :retry, :reset, :resume, :halt, :kill], [Jobduct::Channel] do |channel|
          channel.channel_group.present? && can?(:read, ActiveFedora::Base.load_instance_from_solr(channel.channel_group))
        end
        can [:show, :call, :resend, :tunnel_callback], [Jobduct::Callback] do |callback| can?(:show, callback.channel) end
      elsif user.is_registered?
      else
      end
    end
  end
end
