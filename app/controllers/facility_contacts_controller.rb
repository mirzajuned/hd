class FacilityContactsController < ApplicationController
  before_action :authorize
  before_action :session_params, only: [:new, :edit]
  before_action :get_facility_contact, only: [:edit, :update, :destroy]
  before_action :get_contact_groups, only: [:index, :new, :edit]

  def index
    @facility_contacts = FacilityContact.where(facility_id: current_facility.id.to_s, is_deleted: false)
  end

  def new
    @facility_contact = FacilityContact.new
  end

  def create
    @facility_contact = FacilityContact.new(facility_contact_params)

    if @facility_contact.save
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      get_contact_groups
      render 'new'
    end
  end

  def edit
  end

  def update
    if @facility_contact.update_attributes(facility_contact_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      get_contact_groups
      render 'edit'
    end
  end

  def destroy
    @facility_contact.update(is_deleted: true)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def get_contact_details
    @contacts = FacilityContact.where(facility_id: current_facility.id.to_s, contact_group_id: params[:contact_group_id], for_invoice: params[:for_invoice]).pluck(:id, :display_name)

    render json: { "contact_fields": @contacts }
  end

  private

  def session_params
    @current_facility, @current_user = current_facility, current_user
  end

  def get_facility_contact
    @facility_contact = FacilityContact.find_by(id: params[:id])
  end

  def get_contact_groups
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id)
    @contact_groups_hash = @contact_groups.map { |cg| { id: cg.id.to_s, name: cg.name } }
  end

  def facility_contact_params
    params.require(:facility_contact).permit(:organisation_id, :facility_id, :salutation, :first_name, :middle_name, :last_name, :company_name, :display_name, :abbreviation, :email, :work_number, :mobile_number, :address_line_1, :address_line_2, :city, :state, :pincode, :contact_group_id, :for_invoice, :for_expense)
  end
end
