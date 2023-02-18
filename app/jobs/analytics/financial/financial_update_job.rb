class Analytics::Financial::FinancialUpdateJob < ActiveJob::Base
  queue_as :urgent
  DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
  def perform(invoice_id, invoice_type, old_amount, _current_user_id = nil)
    @old_amount = old_amount.to_f
    @invoice = Invoice.find_by(id: invoice_id)
    return unless @invoice.present?

    patient = ::Patient.find_by(id: @invoice.patient_id)
    organisation_id = @invoice.try(:organisation_id)
    facility_id = @invoice.try(:facility_id)
    specialty_id = @invoice.try(:specialty_id)
    currency_id = @invoice.currency_id
    date = @invoice.created_at.to_date

    hashed_data = {}
    hashed_data['day'] = date.yday
    hashed_data['week'] = date.cweek
    hashed_data['month'] = date.month
    hashed_data['year'] = date.year

    DATA_CREATION_ARRAY.each_with_index do |type, _indx|
      start_date, _end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(date, type)
      @financial_overview = Analytics::Financial::FinancialOverview.find_by(
        organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
        data_type: type, data_type_range: hashed_data[type], currency_id: currency_id, in_year: start_date.year
      )

      next unless @financial_overview.present?

      @p_type = if patient.opd_visit_count <= 1
                  'New'
                else
                  'Old'
                end

      if invoice_type == 'OPD'
        if @p_type == 'New'
          @financial_overview.opd_new_patient_amount -= @old_amount.to_f
          @financial_overview.opd_new_patient_amount += @invoice.net_amount.to_f
        elsif @p_type == 'Old'
          @financial_overview.opd_old_patient_amount -= @old_amount.to_f
          @financial_overview.opd_old_patient_amount += @invoice.net_amount.to_f
        end
      elsif invoice_type == 'IPD'
        if @p_type == 'New'
          @financial_overview.ipd_new_patient_amount -= @old_amount.to_f
          @financial_overview.ipd_new_patient_amount += @invoice.net_amount.to_f
        elsif @p_type == 'Old'
          @financial_overview.ipd_old_patient_amount -= @old_amount.to_f
          @financial_overview.ipd_old_patient_amount += @invoice.net_amount.to_f
        end
      elsif invoice_type == 'Pharmacy'
        if @p_type == 'New'
          @financial_overview.pharmacy_new_patient_amount -= @old_amount.to_f
          @financial_overview.pharmacy_new_patient_amount += @invoice.total.to_f
        elsif @p_type == 'Old'
          @financial_overview.pharmacy_old_patient_amount -= @old_amount.to_f
          @financial_overview.pharmacy_old_patient_amount += @invoice.total.to_f
        end
      elsif invoice_type == 'Optical'
        if @p_type == 'New'
          @financial_overview.optical_new_patient_amount -= @old_amount.to_f
          @financial_overview.optical_new_patient_amount += @invoice.total.to_f
        elsif @p_type == 'Old'
          @financial_overview.optical_old_patient_amount -= @old_amount.to_f
          @financial_overview.optical_old_patient_amount += @invoice.total.to_f
        end
      end
      @financial_overview.save
    end
  end
end
