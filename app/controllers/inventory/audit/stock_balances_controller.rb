class Inventory::Audit::StockBalancesController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :fetch_balances, only: [:index, :filter_index, :append_index]

  def index
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @time_period = params[:time_period]
    return unless @sub_store_id.blank?

    @opening_stock = 0
    @closing_stock = 0
    @opening_amount = 0
    @closing_amount = 0
    balance_data = @balances.pluck(:opening_stock, :closing_stock, :opening_amount, :closing_amount)
    balance_data.each do |data|
      @opening_stock += data[0]
      @closing_stock += data[1]
      @opening_amount += data[2]
      @closing_amount += data[3]
    end
  end

  def show
    @balance = Inventory::Audit::Balance.find_by(id: params[:id])
    options = { store_id: params[:store_id] }
    options[:sub_store_id] = params[:sub_store_id] unless params[:sub_store_id].blank?
    options[:transaction_date] = { :$gte => params[:start_date], :$lte => params[:end_date] }
    @histories = Inventory::Audit::History.where(options)
  end

  def filter_index; end

  def append_index; end

  private

  def fetch_balances
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @sub_store_id = params[:sub_store_id]
    @store_type_name = params[:store_type_name]
    current_data_row = params[:total_count_row].to_i
    options = { store_id: @store_id }
    options[:date] = { :$gte => @start_date, :$lte => @end_date }
    options[:sub_store_id] = @sub_store_id unless @sub_store_id.blank?
    @balances = Inventory::Audit::Balance.where(options).order_by(created_at: 'desc')
                                         .skip(current_data_row).limit(30)
    return unless @balances.blank?

    options[:date] = { :$gte => Date.yesterday, :$lte => @end_date }
    @balances = Inventory::Audit::Balance.where(options)
  end
end
