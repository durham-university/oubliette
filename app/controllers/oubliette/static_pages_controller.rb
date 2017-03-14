module Oubliette
  class StaticPagesController < Oubliette::ApplicationController
    def home
      @query = params['query']
    end
  end
end
