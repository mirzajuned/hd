class PayerMastersController < ApplicationController
  before_action :authorize
  before_action :set_payer_master, only: [:edit, :update, :clone, :destroy, :enable]
  before_action :set_facilities, only: [:payer_list, :new, :edit, :clone, :clone_multiple, :group_payers_list]

  def index
    @payer_masters = PayerMaster.collection.aggregate(
      [
        { '$match': { organisation_id: current_user.organisation_id } },
        { '$group': { _id: { facility_id: '$facility_id', is_active: '$is_active' }, count: { '$sum': 1 } } },
        { '$group': {
          _id: '$_id.facility_id', facility_count: { '$sum': '$count' },
          active_group: { '$push': { active: '$_id.is_active', count: '$count' } }
        } }
      ]
    ).to_a

    @facilities = Facility.where(:id.in => @payer_masters.pluck(:_id).uniq)
                          .map { |facility| { id: facility.id, name: facility.name, country_id: facility.country_id } }
  end

  def payer_list
    @facility = @facilities.find { |f| f.id.to_s == params[:facility_id] }

    @options = { facility_id: params[:facility_id] }
    @options = @options.merge(is_active: params[:is_active]) if params[:is_active].present?
    @payer_masters = PayerMaster.where(@options).to_a
  end

  def new
    set_new_contact_groups
    fetch_patient_payer_masters
    @payer_master = PayerMaster.new
  end

  def create
    @payer_master = PayerMaster.new(payer_master_params)

    if @payer_master.save!
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      set_edit_contact_groups
      set_facilities

      render 'new'
    end
  end

  def edit
    set_edit_contact_groups
    fetch_patient_payer_masters
  end

  def update
    if @payer_master.update_attributes(payer_master_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      set_edit_contact_groups
      set_facilities

      render 'edit'
    end
  end

  def group_payers_list
    organisation_id = current_user.organisation_id
    @group_payers = Global.payers_list
    @contact_groups = ContactGroup.where(organisation_id: organisation_id, :name.in => ['Insurance', 'TPA'])
                                  .map { |cg| { id: cg.id, name: cg.name } }
  end

  def create_group_payers
    true_params = params[:payer_masters][:payer_detail].delete_if { |_k, pd| pd[:flag] == 'false' }
    true_params.each do |_k, payer_detail|
      payer_master = PayerMaster.find_by(payer_uniq_id: payer_detail[:payer_uniq_id],
                                         facility_id: payer_detail[:facility_id])
      if payer_master.present?
        payer_master.update_attributes(payer_params(payer_detail))
      else
        payer_master = PayerMaster.new(payer_params(payer_detail))
        payer_master.save
      end
    end

    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  def clone
    @payer_masters = PayerMaster.where(organisation_id: current_user.organisation_id,
                                       payer_uniq_id: @payer_master.payer_uniq_id).to_a
    @master_facility_ids = @payer_masters.pluck(:facility_id)
  end

  def clone_multiple
    @payer_masters = PayerMaster.where(facility_id: params[:facility_id]).to_a
  end

  def create_multiple
    user_id = current_user.id.to_s
    facility_ids = params[:facility_ids]
    if params[:id].present?
      PayerMasterJobs::CloneJob.perform_later(params[:id], facility_ids, user_id)
    else
      params[:payer_master_ids].split(',').each do |payer_master_id|
        PayerMasterJobs::CloneMultipleJob.perform_later(payer_master_id, facility_ids, user_id)
      end
    end
  end

  def destroy
    @payer_master&.update_attributes(is_active: false)
  end

  def enable
    @payer_master&.update_attributes(is_active: true)
  end

  def set_payers_list

    contact_group = ContactGroup.find_by(id: params[:contact_group_id])

    # need to replace with type later
    if contact_group.name.to_s.downcase == 'tpa+insurance'
      tpa_contact_group = ContactGroup.find_by(organisation_id: current_user.organisation_id, name: /tpa/i)
      insurance_contact_group = ContactGroup.find_by(organisation_id: current_user.organisation_id, name: /insurance/i)

      payers_list = PayerMaster.where(facility_id: params[:facility_id], contact_group_id: tpa_contact_group.try(:id))
      payers_pricing_list = PayerMaster.where(facility_id: params[:facility_id], contact_group_id: insurance_contact_group.try(:id))

      payers_pricing_list = payers_pricing_list.where(is_active: true) if params[:render_action].present? && params[:render_action] == 'new'
      payers_pricing = payers_pricing_list.pluck(:id, :display_name)

    else
      payers_list = PayerMaster.where(facility_id: params[:facility_id], contact_group_id: params[:contact_group_id])
    end

    payers_list = payers_list.where(is_active: true) if params[:render_action].present? && params[:render_action] == 'new'
    payers = payers_list.pluck(:id, :display_name)

    render json: { "payer_fields": payers , "payers_pricing_fields": payers_pricing,
                   }
  end

  def set_insurer_payers_list
    insurer_payers_master = PayerMaster.find_by(id: params[:invoice_insurer_id])
    insurer_payer_type_id = insurer_payers_master.payer_type_id
    insurance_master = Finance::InsuranceMaster.find_by(id: insurer_payer_type_id)

    render json: { "insurance_master_name": insurance_master.try(:name).to_s, "insurance_master_id": insurance_master.try(:id).to_s}
  end

  def set_tpa_insurance_corporate_payers_list
    payers_master = PayerMaster.find_by(id: params[:payer_master_id])
    payer_type_id = payers_master.payer_type_id
    payer_master_type = params[:payer_master_type]

    if payer_master_type.downcase.include?("tpa")
      tpa_master = Finance::TpaMaster.find_by(id: payer_type_id)
    elsif payer_master_type.downcase == "insurance"
      insurance_master = Finance::InsuranceMaster.find_by(id: payer_type_id)
    elsif payer_master_type.downcase == "panel"
      panel_master = Finance::PanelMaster.find_by(id: payer_type_id)
    end

    dispensary_masters = Finance::DispensaryMaster.where(organisation_id: current_user.organisation_id )
    dispensary_masters = dispensary_masters.where(is_disable: false) unless params[:render_action].present? && params[:render_action] == 'edit' && params[:is_draft] == "false"

    if dispensary_masters
      dispensary_list = dispensary_masters.pluck(:id, :name).uniq
    else
      dispensary_list = []
    end

    insurance_masters = Finance::InsuranceMaster.where(organisation_id: current_user.organisation_id)
    insurance_masters = insurance_masters.where(is_disable: false) unless params[:render_action].present? && params[:render_action] == 'edit' && params[:is_draft] == "false"

    if insurance_masters
      insurance_list = insurance_masters.pluck(:id, :name).uniq
    else
      insurance_list = []
    end

    corporate_masters = Finance::CorporateMaster.where(organisation_id: current_user.organisation_id)
    corporate_masters = corporate_masters.where(is_disable: false) unless params[:render_action].present? && params[:render_action] == 'edit' && params[:is_draft] == "false"

    if corporate_masters
      corporate_list = corporate_masters.pluck(:id, :name).uniq
    else
      corporate_list = []
    end

    # payers_list = Finance::InsuranceMaster.where(organisation_id: current_user.organisation_id, is_disable: false, )
    # payers = payers_list.pluck(:id, :display_name)

    render json: { "insurance_list": insurance_list, "corporate_list": corporate_list, "dispensary_list": dispensary_list,
                   "tpa_master_name": tpa_master.try(:name).to_s, "tpa_master_id": tpa_master.try(:id).to_s,
                   "insurance_master_name": insurance_master.try(:name).to_s, "insurance_master_id": insurance_master.try(:id).to_s,
                   "panel_master_name": panel_master.try(:name).to_s, "panel_master_id": panel_master.try(:id).to_s}
  end

  def set_corporate_payers_list
    payers_master = PayerMaster.find_by(id: params[:payer_master_id])
    invoice_insurer_id = params[:invoice_insurer_id]
    payer_type_id = payers_master.payer_type_id
    tpa_master = Finance::TpaMaster.find_by(id: payer_type_id)
    corporate_details = tpa_master.try(:corporate_details)

    if corporate_details.present?
      @corporate_list  = corporate_details.where(insurance_master_id: invoice_insurer_id).pluck(:corporate_master_id, :corporate_master_name).uniq
    else
      @corporate_list = []
    end

    render json: { "corporate_list": @corporate_list }
  end

  def get_payer_type_master
    payer_type = params[:contact_group_name]
    if payer_type.to_s.downcase.include?("tpa")
      payer_type_master_data = Finance::TpaMaster.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    elsif payer_type.to_s.downcase == 'insurance'
      payer_type_master_data = Finance::InsuranceMaster.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    elsif payer_type.to_s.downcase == 'panel'
      payer_type_master_data = Finance::PanelMaster.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    else
      payer_type_master_data = []
    end
    render json: payer_type_master_data.to_json
  end

  def get_tpa_insurer_type_master
    payer_type_id = params[:payer_type_id]
    tpa_master = Finance::TpaMaster.find_by(id: payer_type_id)
    corporate_details = tpa_master.try(:corporate_details)

    if corporate_details.present?
      @insurance_list  = corporate_details.pluck(:insurance_master_name, :insurance_master_id).uniq
    else
      @insurance_list = []
    end
    # payers_list = Finance::InsuranceMaster.where(organisation_id: current_user.organisation_id, is_disable: false, )
    # payers = payers_list.pluck(:id, :display_name)

    render json: @insurance_list.to_json
  end


  private

  def fetch_patient_payer_masters
    @finance_patient_payer_masters= Finance::PatientPayerDataMaster.where(
        organisation_id: current_organisation['_id'].to_s, is_disable: false).order_by(name: :asc)
  end

  def payer_master_params
    params.require(:payer_master).permit(
      :salutation, :first_name, :middle_name, :last_name, :company_name, :abbreviation, :display_name, :email,
      :mobile_number, :work_number, :city, :district, :commune, :pincode, :state, :address_line_1, :address_line_2,
      :mou_date, :tariff_start_date, :tariff_end_date, :tariff_revised_date, :mou_information, :tariff_comment,
      :contact_group_id, :contact_group_name, :organisation_id, :facility_id, :user_id, :payer_type_id,
      :patient_payer_data_details, :tpa_insurer_type_id, :department, :designation
    )
  end

  def payer_params(payer_detail)
    payer_detail.permit(:facility_id, :user_id, :organisation_id, :contact_group_id, :contact_group_name,
                        :payer_uniq_id, :display_name, :company_name)
  end

  def set_payer_master
    @payer_master = PayerMaster.find_by(id: params[:id])
  end

  def set_new_contact_groups
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id, payer_master_present: true).to_a
  end

  def set_edit_contact_groups
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).to_a
  end

  def set_facilities
    @facilities = Facility.where(organisation_id: current_user.organisation_id).to_a
  end
end
