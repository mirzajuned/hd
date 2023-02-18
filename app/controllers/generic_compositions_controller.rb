class GenericCompositionsController < ApplicationController
  before_action :authorize

  def search
    query = params[:q]
    @generic_compositions = GenericComposition.where(name: /#{Regexp.escape(query)}/i)
  end

  def search_class
    options = { name: /#{Regexp.escape(params[:q])}/i }
    options = options.merge(category: params[:category]) if params[:category].present?
    @generic_compositions = GenericClass.where(options)
  end
end
