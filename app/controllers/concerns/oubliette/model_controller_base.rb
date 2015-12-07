module Oubliette
  module ModelControllerBase
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!, only: [:edit, :update, :destroy, :new, :create, :index]
      before_action :set_resource, only: [:show, :edit, :update, :destroy]
      before_action :authorize_resource!
      before_action :check_allow_destroy, only: [:destroy]
    end

    def authenticate_user!(opts={})
      authenticate_api_user
      super(opts) unless warden.user
    end

    def authenticate_api_user
      if Oubliette.config['api_debug'] && params['api_debug']
        # This is for debugging and development only. Allows full access simply
        # by setting the api_debug parameter in the request.
        warden.request.env['devise.skip_trackable'] = true
        warden.set_user(User.new(roles: ['api']))
        true
      else
        false
      end
    end

    def index
      if use_paging?
        per_page = [[params.fetch('per_page', 20).to_i, 100].min, 5].max
        page = [params.fetch('page', 1).to_i, 1].max
        resources = @parent.try(:"#{self.controller_name}")
        if resources
          resources = self.class.resources_for_page(page: page, per_page: per_page, from: resources)
        else
          resources = self.class.resources_for_page(page: page, per_page: per_page)
        end
      else
        resources = @parent.try(:"#{self.controller_name}")
        resources = self.class.model_class.all if !resources
      end

      respond_to do |format|
        format.html {
          @resources = resources
          instance_variable_set(:"@#{self.controller_name}",resources)
          render
        }
        format.json {
          response = { resources: resources.map(&:as_json) }
          if resources.is_a? PagingScope
            response[:page] = resources.current_page
            response[:total_pages] = resources.total_pages
          end
          render json: response
        }
      end
    end

    def show
      respond_to do |format|
        format.html {
          @presenter = presenter
          render
        }
        format.json {
          render json: @resource.as_json
        }
      end
    end

    def new
      set_resource( new_resource )
    end

    def edit
    end

    def create
      set_resource( new_resource(resource_params) )

      respond_to do |format|
        if @resource.valid? && @resource.save
          format.html { redirect_to @resource, notice: "#{self.class.model_name.capitalize} was successfully created." }
          format.json { render json: {status: :created, resource: @resource.as_json } }
        else
          format.html { render :new }
          format.json { render json: @resource.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      @form = edit_form
      respond_to do |format|
        if @resource.update(resource_params)
          format.html { redirect_to @resource, notice: "#{self.class.model_name.capitalize} was successfully updated." }
          format.json { render :show, status: :ok, location: @resource }
        else
          format.html { render :edit }
          format.json { render json: @resource.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      redirect = try(:"#{self.controller_name}_url") || root_url

      @resource.destroy
      respond_to do |format|
        format.html { redirect_to redirect, notice: "#{self.class.model_name.capitalize} was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    protected

    def use_paging?
      true
    end

    def new_resource(params={})
      self.class.model_class.new(params)
    end

    def set_resource(resource = nil)
      if resource
        @resource = resource
      else
        @resource = self.class.model_class.find(params[:id])
      end
      self.instance_variable_set(:"@#{self.class.model_name}",@resource)
      @form = edit_form
    end

    def check_allow_destroy
      raise 'Not allowed to destroy this resource' unless @resource.try(:allow_destroy?)
    end

    def authorize_resource!
      authorize!(params[:action].to_sym, @resource || self.class.model_class)
    end

    def presenter(resource=nil)
      self.class.presenter_class.new(resource || @resource)
    end

    def edit_form(resource=nil)
      self.class.edit_form_class.new(resource || @resource)
    end

    def resource_params
      self.class.edit_form_class.model_attributes(params.require(self.class.model_name.to_sym))
    end

    module ClassMethods
      def resources_for_page(*args)
        page = 1
        page = args.shift.to_i if args.first.is_a?(Integer) || args.first.is_a?(String)
        options = args.last || {}
        page = options.fetch(:page, page)
        per_page = options.fetch(:per_page, 20)
        from = options.fetch(:from, model_class)
        total_pages = (from.count.to_f / per_page).ceil
        PagingScope.new(
          from.order('ingestion_date_dtsi desc').limit(per_page).offset((page-1)*per_page),
          total_pages,
          page )
      end

      def model_class
        @model_class ||= "Oubliette::#{self.controller_name.classify}".constantize
      end

      def model_name
        @model_name ||= self.controller_name.singularize
      end

      def presenter_terms
        [:title]
      end

      def form_terms
        presenter_terms
      end

      def presenter_class
        DurhamRails::GenericPresenter.presenter_class_for(model_class, presenter_terms)
      end

      def edit_form_class
        DurhamRails::GenericForm.form_class_for(model_class, form_terms)
      end
    end

    class PagingScope
      attr_accessor :relation, :total_pages, :current_page
      def initialize(relation, total_pages, current_page)
        @relation = relation
        @total_pages = total_pages
        @current_page = current_page
      end

      def method_missing(name, *args, &block)
        @relation.send(name, *args, &block)
      end
    end
  end
end
