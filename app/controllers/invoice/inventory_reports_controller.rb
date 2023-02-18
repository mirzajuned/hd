class Invoice::InventoryReportsController < ApplicationController
  before_action :authorize
  before_action :collection_report_params, only: [:pharmacy_sales_report, :optical_sales_report]

  def pharmacy_sales_report
    if params[:format] == 'pdf'
      html_template = 'invoice/inventory_reports/pharmacy_sales_report.html.erb'
      respond_to do |format|
        format.html
        format.pdf do
          @pdf = render_to_string pdf: 'mashpy', template: html_template, encoding: 'UTF-8',
                                  layout: 'invoice/inventory/pdfgen.html.erb', viewport_size: '1280 x 1024',
                                  page_size: 'A4', show_as_html: params[:debug].present?,
                                  footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
          send_data(@pdf, filename: "#{@filename}.pdf", type: 'application/pdf')
        end
      end
    else
      respond_to do |format|
        format.html
        format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
      end
    end
  end

  def optical_sales_report
    if params[:format] == 'pdf'
      html_template = 'invoice/inventory_reports/pharmacy_sales_report.html.erb'
      respond_to do |format|
        format.html
        format.pdf do
          @pdf = render_to_string pdf: 'mashpy', template: html_template, encoding: 'UTF-8',
                                  layout: 'invoice/inventory/pdfgen.html.erb', viewport_size: '1280 x 1024',
                                  page_size: 'A4', show_as_html: params[:debug].present?,
                                  footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
          send_data(@pdf, filename: "#{@filename}.pdf", type: 'application/pdf')
        end
      end
    else
      respond_to do |format|
        format.html
        format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
      end
    end
  end

  def collection_report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  private

  def collection_report_params
    store = Inventory::Store.find(params[:store_id])
    options = { store_id: params[:store_id], start_date: Time.parse(params['start_date'] + ' ' + params['start_time']),
                end_date: Time.parse(params['end_date'] + ' ' + params['end_time']), user: params[:user_id], is_deleted: false,
                sort: params[:sort] }
    @user = params[:user_id] == 'all_user' ? 'All User' : User.find(params[:user_id]).fullname
    calculate_collection_sales_report(options, params[:user_id])
    @facility_name = Facility.find(store.facility_id).display_name
    @store_name = store.name
    @summary = "#{store.name} Summary"
    @address = store.address
    @filter_data = [['Start Date', params[:start_date]], ['End Date', params[:end_date]], ['Store Name', @store_name],
                    ['Facility Name', @facility_name], ['Address', @address], ['Sort By', params[:sort]], ['User', @user]]
    @filename = "#{store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_collection_report"
  end

  def calculate_collection_sales_report(params, user_id)
    @user_id = user_id
    @invoice_params = params
    @data_array = []
    options = { receipt_time: params[:start_date]..params[:end_date], store_id: params[:store_id] }
    options = options.merge(user_id: user_id) if user_id != 'all_user'
    order_by = params[:sort] == 'Time' ? 'receipt_time' : 'user_id'
    total_list = Finance::CollectionTransactionData.where(options).order_by("#{order_by} ASC")
    @data_array = Inventory::Report::CollectionReportService.call(total_list)
    calculate_user_wise_data(total_list)
  end

  def calculate_user_wise_data(total_list)
    @total_collection_amount = 0
    @total_refund_amount = 0
    @total_advance_amount = 0
    @total_bill_amount = 0

    @total_collection_amount_mop = Hash.new(0.0)
    @total_refund_amount_mop = Hash.new(0.0)
    @total_advance_amount_mop = Hash.new(0.0)
    @total_bill_amount_mop = Hash.new(0.0)

    total_list = total_list.group_by(&:user_id)
    @user_wise_summary_array = []
    total_list.each_key do |key|
      @user_name = User.find_by(id: key)
      @user_name_summary = "#{@user_name&.fullname} Summary"
      @user_collection_amount = 0
      @user_bill_amount = 0
      @user_advance_amount = 0
      @user_refund_amount = 0

      @user_collection_amount_mop = Hash.new(0.0)
      @user_refund_amount_mop = Hash.new(0.0)
      @user_bill_amount_mop = Hash.new(0.0)
      @user_advance_amount_mop = Hash.new(0.0)
      @user_collection_data = total_list[key]
      @user_collection_data.each_with_index do |receipt, _abc|
        receipt_info = receipt[:receipt_display_fields]
        if receipt[:is_refund]
          @user_refund_amount += receipt_info[:receipt_amount].to_f
          @user_refund_amount_mop[receipt_info[:mode_of_payment]] = @user_refund_amount_mop[receipt_info[:mode_of_payment]].to_f + receipt_info[:receipt_amount].to_f
        else
          if receipt[:is_advance]
            @user_advance_amount += receipt_info[:receipt_amount].to_f
            @user_advance_amount_mop[receipt_info[:mode_of_payment]] = @user_advance_amount_mop[receipt_info[:mode_of_payment]].to_f + receipt_info[:receipt_amount].to_f
          elsif receipt[:is_bill]
            @user_bill_amount += receipt_info[:receipt_amount].to_f
            @user_bill_amount_mop[receipt_info[:mode_of_payment]] = @user_bill_amount_mop[receipt_info[:mode_of_payment]].to_f + receipt_info[:receipt_amount].to_f
          end
          @user_collection_amount += receipt_info[:receipt_amount].to_f
          @user_collection_amount_mop[receipt_info[:mode_of_payment]] = @user_collection_amount_mop[receipt_info[:mode_of_payment]].to_f + receipt_info[:receipt_amount].to_f
        end
      end

      @user_collection_refund_amount = @user_collection_amount.to_f - @user_refund_amount.to_f

      @user_array = []

      @user_key_arr = ['MOP']
      @user_collection_amount_mop.each do |key, value|
        @total_collection_amount_mop[key] = @total_collection_amount_mop[key] + value
        @user_key_arr << key << value
      end
      @user_val_arr = [
        @user_name_summary, 'Adv. Collection', @user_advance_amount, 'Bill Collection', @user_bill_amount,
        'Total Refund', @user_refund_amount, 'Total Net Collection', @user_collection_refund_amount
      ]
      @user_wise_summary_array << @user_key_arr << @user_val_arr
      @user_wise_summary_array << []

      @user_refund_amount_mop.each do |key, value|
        @total_refund_amount_mop[key] = @total_refund_amount_mop[key] + value
      end

      @user_bill_amount_mop.each do |key, value|
        @total_bill_amount_mop[key] = @user_bill_amount_mop[key] + value
      end

      @user_advance_amount_mop.each do |key, value|
        @total_advance_amount_mop[key] = @user_advance_amount_mop[key] + value
      end

      @total_mop_array = []
      @total_collection_amount_mop.each do |key, value|
        @total_mop_array << key << value
      end

      @total_collection_amount += @user_collection_amount
      @total_refund_amount += @user_refund_amount
      @total_bill_amount += @user_bill_amount
      @total_advance_amount += @user_advance_amount
      @total_collection_refund_amount = @total_collection_amount.to_f - @total_refund_amount.to_f

      @total_val_array = [
        'Adv. Collection', @total_advance_amount, 'Bill Collection', @total_bill_amount, 'Refund',
        @total_refund_amount, 'Net Collection', @total_collection_refund_amount
      ]
    end
  end
end
