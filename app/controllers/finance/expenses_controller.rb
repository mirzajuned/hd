class Finance::ExpensesController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def expense_list
    if params[:status] == "All" || params[:status].blank?
      @expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    else
      @expenses = Finance::Expense.where(status: params[:status], facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    end
    @expense_status = params[:status]
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def dashboard
    @total_expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false)
    @total_paid_expenses = @total_expenses.where(status: 'Paid')
    @total_unpaid_expenses = @total_expenses.where(status: 'Unpaid')
    @total_inprocess_expenses = @total_expenses.where(status: 'In process')

    @todays_expenses = @total_expenses.where(date: Date.today)
    @todays_paid_expenses = @todays_expenses.where(status: 'Paid')
    @todays_unpaid_expenses = @todays_expenses.where(status: 'Unpaid')
    @todays_inprocess_expenses = @todays_expenses.where(status: 'In process')

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def recurring
    if params[:status] == "All" || params[:status].blank?
      @recurring_expenses = Finance::RecurringExpense.where(facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    else
      @recurring_expenses = Finance::RecurringExpense.where(status: params[:status], facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    end
    @recurring_expense_status = params[:status]
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def index
    @total_expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false)
    @total_paid_expenses = @total_expenses.where(status: 'Paid')
    @total_unpaid_expenses = @total_expenses.where(status: 'Unpaid')
    @total_inprocess_expenses = @total_expenses.where(status: 'In process')

    @todays_expenses = @total_expenses.where(date: Date.today)
    @todays_paid_expenses = @todays_expenses.where(status: 'Paid')
    @todays_unpaid_expenses = @todays_expenses.where(status: 'Unpaid')
    @todays_inprocess_expenses = @todays_expenses.where(status: 'In process')
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def get_expense_data
    @expense = Finance::Expense.find_by(id: params[:expense_id])
    respond_to do |format|
      format.js {}
    end
  end

  def upload_expense_file
    @expense = Finance::Expense.find_by(:id => params[:expenseId])
    @expense_upload = @expense.expense_receipts.create!(asset_path: params[:files])
  end

  def delete_upload
    @expense = Finance::Expense.find_by(:id => params[:expense_id])
    @expense.expense_receipts.find_by(:id => params[:id]).delete
    head :no_content
  end

  def new
    @current_user = current_user
    @contacts = Contact.includes(:contact_group).where(organisation_id: @current_user.organisation_id, is_deleted: false, for_expense: true)
    @tax_groups = TaxGroup.where(:organisation_id.in => [@current_user.organisation_id, $HG_ORGANISATION_ID], is_deleted: false).order(created_at: :desc)
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)
    @expense = Finance::Expense.new
  end

  def create
    @expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    @expense = Finance::Expense.new(finance_expense_params)
    respond_to do |format|
      if @expense.save
        Analytics::Expenses::ExpensesOverviewJob.perform_later(@expense.id.to_s, current_user.id.to_s)
        format.js {}
      else
        format.js { render :new }
      end
    end
  end

  def edit
    @current_user = current_user
    @contacts = Contact.includes(:contact_group).where(organisation_id: @current_user.organisation_id, is_deleted: false, for_expense: true)
    @tax_groups = TaxGroup.where(:organisation_id.in => [@current_user.organisation_id, $HG_ORGANISATION_ID], is_deleted: false).order(created_at: :desc)
    @expense =  Finance::Expense.find_by(:id => params[:id])
    @currency = Currency.find_by(id: @expense.currency_id.to_s)
  end

  def update
    @expense = Finance::Expense.find_by(:id => params[:id])
    @old_amount = @expense.amount
    @old_state = @expense.status
    @expense.update_attributes(finance_expense_params)
    Analytics::Expenses::ExpensesOverviewUpdateJob.perform_later(@expense.id.to_s, @old_amount, @old_state, current_user.id.to_s)
    @expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    @expense = Finance::Expense.find_by(:id => params[:id])
    @expense.update(is_deleted: true)
    @expenses = Finance::Expense.where(facility_id: current_facility.id, is_deleted: false).order(created_at: "DESC")
  end

  private

  def finance_expense_params
    params.require(:finance_expense).permit(:date, :organisation_id, :facility_id, :recorded_by, :currency_id, :currency_symbol, :merchant, :category_name, :contact, :amount, :tax, :tax_id, :tax_inclusive, :mop, :description, :reference, :status_color, :status, :note, :tax_amount)
  end
end
