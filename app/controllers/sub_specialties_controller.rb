class SubSpecialtiesController < ApplicationController
  before_action :authorize

  def index
    sub_specialties = SubSpecialty.where(specialty_id: params[:specialty_id]).pluck(:id, :name, :is_default)

    render json: sub_specialties.to_json
  end
end
