# class Analytics::Financial::FinancialAdvanceJob < ActiveJob::Base
#     queue_as :urgent
#     def perform(advance_id, type, old_amount, current_user_id)
#         @advance = AdvancePayment.find_by(id: advance_id)
#         @user = User.find_by(id: current_user_id)
#         if @user.present?
#             if @advance.present?
#                 @financial_overview = Analytics::Financial::FinancialOverview.find_by(date: Date.current, facility_id: @advance.facility_id)
#                 if @financial_overview.present?
#                     if type == "OPD"
#                         @financial_overview.opd_advance_amount = @financial_overview.opd_advance_amount - old_amount
#                         @financial_overview.opd_advance_amount = @financial_overview.opd_advance_amount.to_f + @advance.opd_advance_amount
#                     elsif type == "IPD"
#                         @financial_overview.ipd_advance_count = @financial_overview.ipd_advance_count - old_amount
#                         @financial_overview.ipd_advance_amount = @financial_overview.ipd_advance_amount.to_f + @advance.ipd_advance_amount
#                     end
#                 end
#             end
#         end
#     end
# end
