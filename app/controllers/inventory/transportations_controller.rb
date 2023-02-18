class Inventory::TransportationsController < ApplicationController
    before_action :authorize
    before_action :fetch_transportations, only: [:index]
    before_action :fetch_transportation, only: [:edit, :update, :toggle_disable]

    def index; end

    def new
        @inventory_transportation = Inventory::Transportation.new
    end

    def create
        @inventory_transportation = Inventory::Transportation.new(transportation_params)
        @inventory_transportation.save!
        fetch_transportations
    end
    def edit; end

    def update
        @inventory_transportation.update(transportation_params)
        fetch_transportations
    end

    def toggle_disable
        @inventory_transportation.set(is_disable: params[:is_disable])
    end

    private

    def fetch_transportations
        @inventory_transportations = Inventory::Transportation.where(organisation_id: current_organisation['_id'].to_s).order_by(:created_at=>"DESC")
    end
    
    def fetch_transportation
      @inventory_transportation = Inventory::Transportation.find_by(id: params[:id])
    end

    def transportation_params
        params.require(:inventory_transportation).permit(
            :name, :description, :organisation_id, :last_edited_by, :facility_id
        )
    end
end
