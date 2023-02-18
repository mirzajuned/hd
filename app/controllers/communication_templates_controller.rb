class CommunicationTemplatesController < ApplicationController
  before_action :fetch_category, only: [:toggle_disable]

  def index
    @communication_tempaltes = CommunicationTemplate.where(
      organisation_id: current_organisation['_id'].to_s
    ).order_by(name: :asc)
  end

  def toggle_disable
    @communication_tempalte.set(is_disable: params[:is_disable])
  end

  private

  def fetch_category
    @communication_tempalte = CommunicationTemplate.find_by(id: params[:id])
  end
end
