class InvoiceServiceCardsController < ApplicationController
  require 'spreadsheet'
  before_action :authorize
  before_action :service_card_active, only: [:index, :create, :update, :destroy, :enable, :save_excel_data, :bed_service]
  before_action :invoice_setting, only: [:index, :create, :update, :destroy, :search, :enable, :save_excel_data, :bed_service]

  def index
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @servicecard = InvoiceServiceCard.new

    respond_to do |format|
      format.js {}
    end
  end

  def create
    @servicecard = InvoiceServiceCard.new(service_card_params)

    if @servicecard.save
      respond_to do |format|
        format.js { render "index", layout: false }
      end
    else
      respond_to do |format|
        format.js { render "new", layout: false }
      end
    end
  end

  def update
    @servicecard = InvoiceServiceCard.find(params[:id])

    if @servicecard.update(service_name: params[:service_name])
      respond_to do |format|
        format.js { render "index", layout: false }
      end
    end
  end

  def destroy
    @itemcard = InvoiceItemCard.where(invoice_service_card_id: params[:id]).update_all(card_deleted: true)
    @servicecard = InvoiceServiceCard.find(params[:id]).update(card_deleted: true)

    respond_to do |format|
      format.js { render "index", layout: false }
    end
  end

  def search
    @search = params[:search]
    service_card_active # Private
  end

  def enable
    @itemcard = InvoiceItemCard.where(invoice_service_card_id: params[:id]).update_all(card_deleted: false)
    @servicecard = InvoiceServiceCard.find(params[:id]).update(card_deleted: false)

    respond_to do |format|
      format.js { render "index", layout: false }
    end
  end

  def bed_service
    Room.where(facility_id: current_facility.id).each do |room|
      @room_service = InvoiceServiceCard.find_by(service_id: room.id.to_s)
      if @room_service.nil?
        @service_new = InvoiceServiceCard.new(service_name: room.name, service_type: "Room", service_id: room.id.to_s, created_from: "Settings", card_deleted: false, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
        if @service_new.save
          @service_id = @service_new.id.to_s
        else

        end
      else
        @service_id = @room_service.id.to_s
        @room_service.update_attributes(card_deleted: false)
        puts "Enabled"
      end
      room.beds.each do |bed|
        @invoice_item_card = InvoiceItemCard.find_by(item_id: bed.try(:id).to_s)
        if @invoice_item_card.nil?
          @invoice_new = InvoiceItemCard.new(item_name: "#{bed.try(:name)} - #{bed.try(:code)}", created_from: "Settings", card_deleted: false, item_type: "Bed", item_price: bed.try(:price).to_f, quantity: 1, item_id: bed.try(:id).to_s, invoice_service_card_id: @service_id, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
          if @invoice_new.save
          else
          end
        else
          @invoice_item_card.update_attributes(item_price: bed.try(:price).to_f, quantity: 1, card_deleted: false)
          puts "Enabled"
        end
      end
    end
    respond_to do |format|
      format.js { render "index", layout: false }
    end
  end

  def upload_excel
    respond_to do |format|
      format.js {}
    end
  end

  def download_excel
    send_file(
      "#{Rails.root}/public/ServiceCard.xls",
      filename: "ServiceCard.xls",
      type: "application/xls"
    )
  end

  def save_excel_data
    Spreadsheet.client_encoding = 'UTF-8'
    if params[:uploaded_excel]
      excel_file = Spreadsheet.open params[:uploaded_excel].tempfile
      excel_file.worksheets.each do |worksheet|
        worksheet.each_with_index 1 do |row|
          if (row[2]).to_i <= 0
            @quantity = 1
          else
            @quantity = (row[2]).to_i
          end
          if row[0]
            @invoice_service_card = InvoiceServiceCard.find_by(service_name: row[0], facility_id: current_facility.id)
            if @invoice_service_card.nil?
              @service_new = InvoiceServiceCard.new(service_name: row[0], service_id: BSON::ObjectId.new(), created_from: "Excel", card_deleted: false, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
              if @service_new.save
                @service_id = @service_new.id.to_s
              else
                puts "Error Saving Service"
              end
            else
              @service_id = @invoice_service_card.id.to_s
            end

            @invoice_item_card = InvoiceItemCard.find_by(item_name: row[1], invoice_service_card_id: @service_id, facility_id: current_facility.id)
            if @invoice_item_card.nil?
              @invoice_new = InvoiceItemCard.new(item_name: row[1], created_from: "Excel", card_deleted: false, item_type: "Item", item_price: (row[3]).to_f, quantity: @quantity, item_id: BSON::ObjectId.new(), invoice_service_card_id: @service_id, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
              if @invoice_new.save
                puts "Item Card Saved"
              else
                puts "Error Saving Item"
              end
            else
              @invoice_item_card.update_attributes(item_price: (row[3]).to_f, quantity: @quantity)
            end
          else
            unless @service_id
              @service_new = InvoiceServiceCard.new(service_name: "Untitled", service_id: BSON::ObjectId.new(), created_from: "Excel", card_deleted: false, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
              if @service_new.save
                @service_id = @service_new.id.to_s
              else
                puts "Error Saving Service"
              end
            end
            if @service_id
              @invoice_item_card = InvoiceItemCard.find_by(item_name: row[1], invoice_service_card_id: @service_id, facility_id: current_facility.id)
              if @invoice_item_card.nil?
                @invoice_new = InvoiceItemCard.new(item_name: row[1], created_from: "Excel", card_deleted: false, item_type: "Item", item_price: (row[3]).to_f, quantity: @quantity, item_id: BSON::ObjectId.new(), invoice_service_card_id: @service_id, facility_id: current_facility.id, organisation_id: current_facility.organisation_id, user_id: current_user.id)
                if @invoice_new.save
                  puts "Item Card Saved"
                else
                  puts "Error Saving Item"
                end
              else
                @invoice_item_card.update_attributes(item_price: (row[3]).to_i, quantity: (row[2]).to_i)
              end
            end
          end
        end
      end
      respond_to do |format|
        format.js { render "index", layout: false }
      end
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Please Choose a File', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  rescue Ole::Storage::FormatError
    respond_to do |format|
      format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Please upload only <strong>*.xls</strong> files.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
    end
  end

  private

  def service_card_params
    params.require(:invoice_service_card).permit(:service_name, :created_from, :facility_id, :user_id, :organisation_id)
  end

  def service_card_active
    if @search.present? && @search.length > 2
      @servicecards = InvoiceServiceCard.where(service_name: /#{Regexp.escape(@search)}/i, facility_id: current_facility.id)
    else
      @servicecards = InvoiceServiceCard.where(facility_id: current_facility.id)
    end
    @itemcards = InvoiceItemCard.where(facility_id: current_facility.id)

    @servicecardsenabled = @servicecards.where(card_deleted: false)
    @servicecardsdisabled = @servicecards.where(card_deleted: true)
    @itemcardsenabled = @itemcards.where(card_deleted: false)
    @itemcardsdisabled = @itemcards.where(card_deleted: true)

    @service_card_id = params[:invoice_service_card_id] || 0
  end

  def invoice_setting
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
  end
end
