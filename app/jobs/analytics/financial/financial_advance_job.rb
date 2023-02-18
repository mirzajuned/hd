# class Analytics::Financial::FinancialAdvanceJob < ActiveJob::Base
#     queue_as :urgent
#     def perform(advance_id, type, current_user_id)
#         @advance = AdvancePayment.find_by(id: advance_id)
#         @user = User.find_by(id: current_user_id)
#         if @user.present?
#             if @advance.present?
#                 @financial_overview = Analytics::Financial::FinancialOverview.find_by(date: Date.current, facility_id: @advance.facility_id)
#                 @patient = Patient.find_by(id: @advance.patient_id)
#                     if @patient.opd_visit_count == 0 || @patient.opd_visit_count == 1
#                         @p_type = "New"
#                     else
#                         @p_type = "Old"
#                     end
#                 if @financial_overview.present?
#                     if type == "OPD"
#                         if @p_type == "New"
#                         @financial_overview.opd_advance_amount = @financial_overview.opd_advance_amount.to_f + 1
#                         @financial_overview.opd_advance_count = @financial_overview.opd_advance_count.to_i +  @advance.opd_advance_count
#                     elsif type == "IPD"
#                         @financial_overview.ipd_advance_amount = @financial_overview.ipd_advance_amount.to_f + @advance.ipd_advance_amount
#                         @financial_overview.ipd_advance_count = @financial_overview.ipd_advance_count.to_i +  @advance.ipd_advance_count
#                     end
#                 else
#                     @financial_overview = Analytics::Financial::FinancialOverview.new
#                     if type == "OPD"
#                         @financial_overview.opd_advance_amount = @financial_overview.opd_advance_amount.to_f + 1
#                         @financial_overview.opd_advance_count = @financial_overview.opd_advance_count.to_i +  @advance.opd_advance_count
#                     elsif type == "IPD"
#                         @financial_overview.ipd_advance_amount = @financial_overview.ipd_advance_amount.to_f + @advance.ipd_advance_amount
#                         @financial_overview.ipd_advance_count = @financial_overview.ipd_advance_count.to_i +  @advance.ipd_advance_count
#                     end
#                     @financial_overview.date = Date.current
#                     @financial_overview.user_id = @advance.user_id
#                     @financial_overview.organisation_id = @advance.organisation_id
#                     @financial_overview.facility_id = @advance.facility_id
#                     @financial_overview.save
#                 end
#             end
#         end
#     end
# end
