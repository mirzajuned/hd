class Api::V1::Admin::OrganisationsController < ApiApplicationController
  before_action :doorkeeper_authorize!

  def index
    params[:sort] ||= 'desc'
    params[:sort_by] ||= 'created_at'

    options = {}
    options = options.merge(name: /#{params[:query]}/i) if params[:query].present?

    @organisations = Organisation.includes(:country).where(options).order("#{params[:sort_by]} #{params[:sort]}").to_a

    @specialties = Specialty.where(:id.in => @organisations.pluck(:specialty_ids).flatten).to_a

    @contracts = OrganisationContract.where(:organisation_id.in => @organisations.pluck(:id), active: true).to_a

    render status: :ok
  end

  def show
    @organisation = Organisation.find_by(id: params[:id])

    @facilities = Facility.where(organisation_id: @organisation.id).to_a
    @users = User.where(organisation_id: @organisation.id).to_a

    data_queries

    @specialties = Specialty.where(:id.in => @organisations.pluck(:specialty_ids).flatten).to_a

    render status: :ok
  end

  def show
    @organisation = Organisation.find_by(id: params[:id])

    @facilities = Facility.where(organisation_id: @organisation.id).to_a
    @users = User.where(organisation_id: @organisation.id).to_a

    data_queries

    @specialties = Specialty.where(:id.in => @organisations.pluck(:specialty_ids).flatten).to_a

    render status: :ok
  end

  def show
    @organisation = Organisation.find_by(id: params[:id])

    @facilities = Facility.where(organisation_id: @organisation.id).to_a
    @users = User.where(organisation_id: @organisation.id).to_a

    data_queries

    render status: :ok
  end

  def edit
    organisation = Organisation.find_by(id: params[:id])

    render json: { organisation: organisation }, status: :ok
  end

  def update
    organisation = Organisation.find_by(id: params[:id])
    old_organisation = organisation.attributes.map { |key, value| { key => value } }.reduce(:merge)

    organisation.update_attributes(organisation_params)

    # Update Expiry
    organisation.update_expiry(organisation.account_expiry_date)

    render json: { organisation: organisation.attributes, old_organisation: old_organisation }, status: :ok
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name, :tagline, :account_expiry_date)
  end

  def data_queries
    beginning_of_year = Date.today.beginning_of_year

    @appointments = []
    # Appointment.where(
    #   organisation_id: @organisation.id, :appointmentdate.gte => beginning_of_year,
    #   appointmentstatus: 416774000
    # )

    @admissions = []
    # Admission.where(
    #   organisation_id: @organisation.id, :admissiondate.gte => beginning_of_year, is_deleted: false
    # )

    @pharmacy_prescriptions = []
    # PatientPrescription.where(
    #   :created_at.gte => beginning_of_year, reg_hosp_ids: @organisation.id.to_s
    # )

    @optical_prescriptions = []
    # PatientOpticalPrescription.where(
    #   :created_at.gte => beginning_of_year, reg_hosp_ids: @organisation.id.to_s
    # )
  end
end
