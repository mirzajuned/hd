class Analytics::Expenses::ExpensesOverviewJob < ActiveJob::Base
  queue_as :urgent
  def perform(expense_id, current_user_id)
    @expense = Finance::Expense.find_by(id: expense_id)
    @user = User.find_by(id: current_user_id)
    if @user.present?
      if @expense.present?
        @expanses_overview = Analytics::Expenses::ExpansesOverview.find_by(date: Date.current, facility_id: @expense.facility_id)
        if @expanses_overview.present?
          if @expense.status == "Paid"
            @expanses_overview.total_paid = @expanses_overview.total_paid.to_f + @expense.amount
            @expanses_overview.total_paid_count = @expanses_overview.total_paid_count.to_i + 1
          elsif @expense.status == "In process"
            @expanses_overview.total_in_progress = @expanses_overview.total_in_progress.to_f + @expense.amount
            @expanses_overview.total_in_progress_count = @expanses_overview.total_in_progress_count.to_i + 1
          elsif @expense.status == "Unpaid"
            @expanses_overview.total_unpaid = @expanses_overview.total_unpaid.to_f + @expense.amount
            @expanses_overview.total_unpaid_count = @expanses_overview.total_unpaid_count.to_i + 1
          end
          @expanses_overview.save
        else
          @expanses_overview = Analytics::Expenses::ExpansesOverview.new
          @expanses_overview.date = Date.current
          @expanses_overview.facility_id = @expense.facility_id
          @expanses_overview.organisation_id = @expense.organisation_id
          if @expense.status == "Paid"
            @expanses_overview.total_paid = @expanses_overview.total_paid.to_f + @expense.amount
            @expanses_overview.total_paid_count = @expanses_overview.total_paid_count.to_i + 1
          elsif @expense.status == "In process"
            @expanses_overview.total_in_progress = @expanses_overview.total_in_progress.to_f + @expense.amount
            @expanses_overview.total_in_progress_count = @expanses_overview.total_in_progress_count.to_i + 1
          elsif @expense.status == "Unpaid"
            @expanses_overview.total_unpaid = @expanses_overview.total_unpaid.to_f + @expense.amount
            @expanses_overview.total_unpaid_count = @expanses_overview.total_unpaid_count.to_i + 1
          end
          @expanses_overview.save
        end
      end
    end
  end
end
