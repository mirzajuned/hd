class TaxGroupsController < ApplicationController
  before_action :set_tax_group, only: [:edit, :update, :destroy]
  before_action :set_tax_rates, only: [:new, :edit]

  def new
    @tax_group = TaxGroup.new
  end

  def create
    params[:tax_group][:tax_rate_ids] = params[:tax_group][:tax_rate_ids].split(',')

    @tax_group = TaxGroup.new(tax_group_params)

    if @tax_group.save
      update_tax_rates(params)

      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'new'
    end
  end

  def edit; end

  def update
    params[:tax_group][:tax_rate_ids] = params[:tax_group][:tax_rate_ids].split(',')
    params[:tax_group][:tax_rate_details] = []

    if @tax_group.update_attributes(tax_group_params)
      update_tax_rates(params)

      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @tax_group.update(is_deleted: true)

    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  private

  def tax_group_params
    params.require(:tax_group).permit(:name, :rate, :user_id, :country_id, :organisation_id,
                                      tax_rate_ids: [], tax_rate_details: [])
  end

  def set_tax_group
    @tax_group = TaxGroup.find_by(id: params[:id])
  end

  def set_tax_rates
    organisation_id_array = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_rates = TaxRate.where(:organisation_id.in => organisation_id_array, country_id: country_id, is_deleted: false)
                        .order(created_at: :desc)
  end

  def update_tax_rates(params)
    params[:tax_group][:tax_rate_ids].each do |tax_rate_id|
      @tax_rate = TaxRate.find_by(id: tax_rate_id.to_s)
      if @tax_rate.present?
        @tax_group.push(tax_rate_details: { _id: tax_rate_id, name: @tax_rate.name, rate: @tax_rate.rate })
      end
    end
  end
end
