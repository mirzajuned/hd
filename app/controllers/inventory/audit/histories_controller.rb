class Inventory::Audit::HistoriesController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :fetch_histories, only: [:filter_index, :append_index]

  def index
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @time_period = params[:time_period]
    fetch_histories
  end

  def show
    @history = Inventory::Audit::History.find_by(id: params[:id])
  end

  def filter_index; end

  def append_index; end

  private

  def fetch_histories
    @store_id = params[:store_id]
    @start_date = DateTime.parse(params[:start_date]).strftime('%d/%m/%Y')
    @end_date = DateTime.parse(params[:end_date]).strftime('%d/%m/%Y')
    @transaction_type = params[:transaction_type]
    @sub_store_id = params[:sub_store_id]
    @store_type_name = params[:store_type_name]
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, user_name: /#{Regexp.escape(query)}/i }
    options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    options[:transaction_type] = @transaction_type unless @transaction_type.blank?
    options[:sub_store_id] = @sub_store_id unless @sub_store_id.blank?
    @histories = Inventory::Audit::History.where(options).order_by(created_at: 'desc')
    respond_to do |format|
      format.html { @histories = @histories.skip(current_data_row).limit(30) }
      format.xlsx { xlsx_report }
      format.js { @histories = @histories.skip(current_data_row).limit(30) }
    end
  end

  def xlsx_report
    @filename = "#{@inventory_store.name.downcase}_inventory_audit_history.xlsx"
    headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\""
    @filters = [['Start Date', @start_date], ['End Date', @end_date],
                ['Store Name', @inventory_store.name], ['Facility Name', current_facility.name],
                ['Address', current_facility.address], ['User Name', current_user.fullname]]
  end
end
