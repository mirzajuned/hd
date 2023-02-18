class SurgeryPackage::ItemsController < ApplicationController
  before_action :authorize

  def index
    @facilities = Facility.where(:id.in => current_user.facility_ids)

    @items = SurgeryPackage::Item.where(facility_id: current_facility.id.to_s)
  end

  def new_multiple
    @items = SurgeryPackage::Item.where(facility_id: params[:facility_id])
  end

  def create_multiple
    params[:items]&.each do |_k, item|
      if item[:id].nil?
        sp_item = SurgeryPackage::Item.new(item_params(item))
        sp_item.save!
      else
        sp_item = SurgeryPackage::Item.find_by(id: item[:id])
        sp_item.update!(item_params(item))
      end
    end
  end

  private

  def item_params(item)
    item.permit(:id, :name, :type, :user_id, :facility_id, :organisation_id)
  end
end
