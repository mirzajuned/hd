class TaxRatesController < ApplicationController
  before_action :find_tax_rate, only: [:edit, :update, :destroy]

  def new
    @tax_rate = TaxRate.new
  end

  def create
    @tax_rate = TaxRate.new(tax_rate_params)

    if @tax_rate.save
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @tax_rate.update_attributes(tax_rate_params)
      respond_to do |format|
        format.js { render 'close.js.erb' }
      end
    else
      render 'edit'
    end
  end

  def destroy
    @tax_rate.update(is_deleted: true)

    respond_to do |format|
      format.js { render 'close.js.erb' }
    end
  end

  private

  def tax_rate_params
    params.require(:tax_rate).permit(:name, :rate, :type, :user_id, :country_id, :organisation_id)
  end

  def find_tax_rate
    @tax_rate = TaxRate.find_by(id: params[:id])
  end
end
