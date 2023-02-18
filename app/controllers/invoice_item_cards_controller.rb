class InvoiceItemCardsController < ApplicationController
  before_action :authorize
  before_action :invoice_item_card, only: [:edit, :update, :destroy, :enable]
  before_action :service_card_active, only: [:create, :update, :destroy, :enable]
  before_action :invoice_setting, only: [:new, :edit, :create, :update, :destroy, :enable]

  def new
    @service_card = InvoiceServiceCard.find(params[:service_card_id])
    @users = User.where(facility_ids: current_facility.id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)

    respond_to do |format|
      format.js {}
    end
  end

  def create
    params[:invoice_item_card].each do |i, val|
      @doctor = User.find(val[:item_id])
      @user_name = (@doctor.fullname if @doctor) || nil
      unless val[:item_name] == ""
        if val[:item_price] == ""
          val[:item_price] = 0.0
        end
        if val[:quantity] == ""
          val[:quantity] = 1
        end

        InvoiceItemCard.create(item_name: val[:item_name], invoice_service_card_id: params[:invoice_service_card_id], user_id: params[:user_id], facility_id: params[:facility_id], organisation_id: params[:organisation_id], created_from: params[:created_from], item_type: val[:item_type], quantity: val[:quantity], item_price: val[:item_price], item_id: val[:item_id], user_name: @user_name, amount: val[:amount], tax_group_id: val[:tax_group_id], tax_inclusive: val[:tax_inclusive], taxable_amount: val[:taxable_amount], non_taxable_amount: val[:non_taxable_amount], sac: val[:sac])
      end
    end
    # redirect_to invoice_service_cards_path(invoice_service_card_id: params[:invoice_service_card_id])
    respond_to do |format|
      format.js { render 'close' }
    end
  end

  def edit
    @users = User.where(facility_ids: current_facility.id.to_s)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    respond_to do |format|
      format.js {}
    end
  end

  def update
    if @itemcard.update_attributes(item_card_params)
      @doctor = User.find(@itemcard.item_id)
      @user_name = (@doctor.fullname if @doctor) || nil
      @itemcard.update(user_name: @user_name)
      # redirect_to invoice_service_cards_path(invoice_service_card_id: @itemcard.invoice_service_card_id.to_s), status: 303
      respond_to do |format|
        format.js { render 'close' }
      end
    end
  end

  def destroy
    @itemcard.update(card_deleted: true)
    # redirect_to invoice_service_cards_path(invoice_service_card_id: @itemcard.invoice_service_card_id.to_s), status: 303
    respond_to do |format|
      format.js { render 'close' }
    end
  end

  def enable
    @servicecard = InvoiceServiceCard.find(@itemcard.invoice_service_card_id.to_s).update(card_deleted: false)
    @itemcard.update(card_deleted: false)
    # redirect_to invoice_service_cards_path(invoice_service_card_id: @itemcard.invoice_service_card_id.to_s), status: 303
    respond_to do |format|
      format.js { render 'close' }
    end
  end

  def get_items_for_service
    @isc = InvoiceServiceCard.find_by(id: params[:service_id]).try(:id).to_s
    @invoice_item_card = InvoiceItemCard.where(facility_id: current_facility.id, card_deleted: false, invoice_service_card_id: @isc).pluck(:id, :item_name, :user_name)
    render json: { "invoice_item_card": @invoice_item_card }
  end

  def get_item_card_details
    @invoice_item_card = InvoiceItemCard.find_by(id: params[:item_id])

    render json: { 'invoice_item_card': @invoice_item_card }
  end

  private

  def item_card_params
    params.require(:invoice_item_card).permit(:item_name, :item_type, :item_price, :quantity, :item_id, :user_name, :amount, :tax_group_id, :tax_inclusive, :taxable_amount, :non_taxable_amount, :created_from, :invoice_service_card_id, :user_id, :facility_id, :organisation_id, :sac)
  end

  def invoice_item_card
    @itemcard = InvoiceItemCard.find(params[:id])
  end

  def service_card_active
    @servicecards = InvoiceServiceCard.where(facility_id: current_facility.id)
    @itemcards = InvoiceItemCard.where(facility_id: current_facility.id)
    @servicecardsenabled = @servicecards.where(card_deleted: false)
    @servicecardsdisabled = @servicecards.where(card_deleted: true)
    @itemcardsenabled = @itemcards.where(card_deleted: false)
    @itemcardsdisabled = @itemcards.where(card_deleted: true)

    @service_card_id = params[:invoice_service_card_id] || @itemcard.try(:invoice_service_card_id) || 0
  end

  def invoice_setting
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
  end
end
