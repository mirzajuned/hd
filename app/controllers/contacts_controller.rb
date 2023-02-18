class ContactsController < ApplicationController
  before_action :authorize
  before_action :session_params, only: [:new, :edit]
  before_action :get_contact, only: [:edit, :update, :destroy]
  before_action :get_contact_groups, only: [:index, :new, :edit]

  def index
    @contacts = Contact.where(organisation_id: current_user.organisation_id).order_by('created_at DESC')
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id)
  end

  def new
    @form_type = params[:form_type]
    @contact = Contact.new
    @contact_group = ContactGroup.where(organisation_id: current_user.organisation_id, contact_group_type: @form_type)
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.save
      FacilityContactsJob.perform_later(@contact.id.to_s) if @contact.update_facility_contact

      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'new'
    end
  end

  def edit
    @form_type = @contact.contact_type
    @contact_group = ContactGroup.where(organisation_id: current_user.organisation_id, contact_group_type: @form_type)
  end

  def update
    if @contact.update_attributes(contact_params)
      FacilityContactsJob.perform_later(@contact.id.to_s) if @contact.update_facility_contact

      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @contact.update(is_deleted: true)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def enable_contact
    @contact = Contact.find_by(id: params[:id])
    @contact.update(is_deleted: false)
    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def filter_search_contact
    options = { organisation_id: current_user.organisation_id }
    options = options.merge(display_name: /#{Regexp.escape(params[:search])}/i) if params[:search].present?
    options = options.merge(contact_group_id: params[:contact_group_id]) if params[:contact_group_id] != 'all'

    @contacts = Contact.where(options)
  end

  def get_contact_details
    @contacts = Contact.where(contact_group_id: params[:contact_group_id], for_invoice: params[:for_invoice]).pluck(:id, :display_name)

    render json: { "contact_fields": @contacts }
  end

  def tpa_list_view
    @current_user = current_user
    @contact_groups = ContactGroup.where(organisation_id: @current_user.organisation_id, contact_group_type: "tpa")
    @contact = @contact_groups.find_by(name: 'Insurance')
    @contacts = Contact.where(organisation_id: @current_user.organisation_id, provided_by: 'HG', contact_group_id: @contact.try(:id))
  end

  def tpa_list_save
    params.permit!
    @contacts_list = params[:contacts]
    @contacts_list.values.each_with_index do |contact|
      @contact = Contact.find_by(id: contact["id"])
      if contact["flag"] == "true"
        flag = false
      else
        flag = true
      end
      @contact.update_attributes(is_deleted: flag) if @contact.present?
    end
  end

  def get_tpa_contacts
    @contacts = Contact.where(organisation_id: current_user.organisation_id, contact_group_id: params[:contact_group_id], provided_by: 'HG')
  end

  private

  def session_params
    @current_facility, @current_user = current_facility, current_user
  end

  def get_contact
    @contact = Contact.find_by(id: params[:id])
  end

  def get_contact_groups
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id)
    @contact_groups_hash = @contact_groups.map { |cg| { id: cg.id.to_s, name: cg.name } }
  end

  def contact_params
    params.require(:contact).permit(:salutation, :first_name, :middle_name, :last_name, :company_name, :display_name, :abbreviation, :email, :contact_type, :work_number, :mobile_number, :address_line_1, :address_line_2, :city, :state, :pincode, :for_invoice, :for_expense, :update_facility_contact, :contact_group_id, :organisation_id, :district, :commune)
  end
end
