class Api::V1::Admin::OrganisationContractsController < ApiApplicationController
  before_action :doorkeeper_authorize!

  def index
    @organisation = Organisation.find_by(id: params[:organisation_id])
    @organisation_contracts = OrganisationContract.where(organisation_id: params[:organisation_id])
                                                  .order(active: :desc, deleted: :asc, start_date: :desc).to_a

    render status: :ok
  end

  def create
    @organisation_contract = OrganisationContract.new(organisation_contract_params)

    @organisation_contract.save!

    render json: {}, status: :created
  rescue Mongoid::Errors::Validations
    render status: :unprocessable_entity
  rescue StandardError => e
    puts e.message
  end

  def destroy
    @organisation_contract = OrganisationContract.find_by(id: params[:id])

    @organisation_contract.set(deleted: true)

    render json: {}, status: :accepted
  end

  private

  def organisation_contract_params
    params.require(:organisation_contract).permit(
      :customer_setup, :customer_type, :subscription_type, :pricing_type, :start_date, :end_date,
      :paid_quota, :free_quota, :variable_quota, :base_rate_per_user, :discount_per_user,
      :created_by, :organisation_id
    )
  end
end
