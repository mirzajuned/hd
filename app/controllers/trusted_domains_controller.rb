class TrustedDomainsController < ApplicationController
  before_action :authorize
  before_action :find_trusted_domain, only: [:disable, :enable, :destroy]

  def index
    @trusted_domains = TrustedDomain.where(organisation_id: current_user.organisation_id, deleted: false)
  end

  def new
    @trusted_domain = TrustedDomain.new
  end

  def create
    @trusted_domain = TrustedDomain.new(trusted_domain_params)

    return if @trusted_domain.save

    respond_to do |format|
      format.js { render 'errors.js.erb' }
    end
  end

  def disable
    @trusted_domain.set(disabled: true)
  end

  def enable
    @trusted_domain.set(disabled: false)
  end

  def destroy
    @trusted_domain.set(deleted: true)
  end

  private

  def trusted_domain_params
    params.require(:trusted_domain).permit(:name, :organisation_id)
  end

  def find_trusted_domain
    @trusted_domain = TrustedDomain.find_by(id: params[:id])
  end
end
