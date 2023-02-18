class Orders::AdvisedController < ApplicationController
    before_action :authorize
  
    def index
      @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
      
      respond_to do |format|
        format.js
      end    
    end
  
    def data
      if params[:sSearch].present?
        @orders = ::Order::Advised.or(procedurename: /#{Regexp.escape(params[:sSearch])}/i, investigationname: /#{Regexp.escape(params[:sSearch])}/i).and(case_sheet_id: params[:case_sheet_id], active: true, type: params[:type])
        .order('advised_datetime ' + params[:sSortDir_0])
      else
        @orders = ::Order::Advised.where(active: true, case_sheet_id: params[:case_sheet_id], type: params[:type])
        .order('advised_datetime ' + params[:sSortDir_0])
      end
      
      @total_orders_count = @orders.count
      @s_echo = params[:sEcho]
  
      respond_to do |format|
        format.json {}
      end
    end
  end