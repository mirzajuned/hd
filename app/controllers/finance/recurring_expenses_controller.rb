class Finance::RecurringExpensesController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout 'loggedin'

  def get_expense_data
    @expense = Finance::RecurringExpense.find_by(id: params[:expense_id])
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @contacts = Contact.includes(:contact_group)
                       .where(organisation_id: current_user.organisation_id, is_deleted: false, for_expense: true)
    organisation_ids = [current_user.organisation_id, $HG_ORGANISATION_ID]
    country_id = current_facility.country_id
    @tax_groups = TaxGroup.where(:organisation_id.in => organisation_ids, country_id: country_id, is_deleted: false)
                          .order(created_at: :desc)
    @recurring_expense = Finance::RecurringExpense.new
  end
end
