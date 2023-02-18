class Analytics::Financial::FinancialJob < ActiveJob::Base
  queue_as :urgent
  DATA_CREATION_ARRAY = ['day', 'week', 'month', 'year'].freeze
  def perform(invoice_id, invoice_type)
    @invoice = ::Invoice.find_by(id: invoice_id)
    return unless @invoice.present?

    patient = ::Patient.find_by(id: @invoice.patient_id)
    @date = @invoice.created_at.to_date
    facility_id = @invoice.try(:facility_id)
    specialty_id = @invoice.try(:specialty_id)
    organisation_id = @invoice.try(:organisation_id)
    currency_id = @invoice.currency_id
    currency_symbol = @invoice.currency_symbol

    hashed_data = {}
    hashed_data['day'] = @date.yday
    hashed_data['week'] = @date.cweek
    hashed_data['month'] = @date.month
    hashed_data['year'] = @date.year

    DATA_CREATION_ARRAY.each_with_index do |type, _indx|
      start_date, end_date = Analytics::AnalyticsDate::QueryGenerator.start_end_date(@date, type)
      @financial_overview = Analytics::Financial::FinancialOverview.find_by(
        organisation_id: organisation_id, facility_id: facility_id, specialty_id: specialty_id,
        data_type: type, data_type_range: hashed_data[type], currency_id: currency_id, in_year: start_date.year
      )

      @financial_overview = Analytics::Financial::FinancialOverview.new if @financial_overview.blank?

      @p_type = patient.reg_date == Date.today ? 'New' : 'Old'

      if invoice_type == 'OPD'
        @financial_overview.opd_invoice_count += 1
        if @p_type == 'New'
          @financial_overview.opd_new_patient_amount += @invoice.net_amount.to_f
        elsif @p_type == 'Old'
          @financial_overview.opd_old_patient_amount += @invoice.net_amount.to_f
        end
      elsif invoice_type == 'IPD'
        @financial_overview.ipd_invoice_count += 1
        if @p_type == 'New'
          @financial_overview.ipd_new_patient_amount += @invoice.net_amount.to_f
        elsif @p_type == 'Old'
          @financial_overview.ipd_old_patient_amount += @invoice.net_amount.to_f
        end
      elsif invoice_type == 'Pharmacy'
        if @invoice.is_canceled == true
          @financial_overview.pharmacy_invoice_count -= 1
          if @p_type == 'New'
            @financial_overview.pharmacy_new_patient_amount -= @invoice.total.to_f
          elsif @p_type == 'Old'
            @financial_overview.pharmacy_old_patient_amount -= @invoice.total.to_f
          end
        else
          @financial_overview.pharmacy_invoice_count += 1
          if @p_type == 'New'
            @financial_overview.pharmacy_new_patient_amount += @invoice.total.to_f
          elsif @p_type == 'Old'
            @financial_overview.pharmacy_old_patient_amount += @invoice.total.to_f
          end
        end
      elsif invoice_type == 'Optical'
        if @invoice.is_canceled == true
          @financial_overview.optical_invoice_count -= 1
          if @p_type == 'New'
            @financial_overview.optical_new_patient_amount -= @invoice.total.to_f
          elsif @p_type == 'Old'
            @financial_overview.optical_old_patient_amount -= @invoice.total.to_f
          end
        else
          @financial_overview.optical_invoice_count += 1
          if @p_type == 'New'
            @financial_overview.optical_new_patient_amount += @invoice.total.to_f
          elsif @p_type == 'Old'
            @financial_overview.optical_old_patient_amount += @invoice.total.to_f
          end
        end
      end

      if @financial_overview.new_record?
        @financial_overview.start_date = start_date
        @financial_overview.end_date = end_date
        @financial_overview.organisation_id = organisation_id
        @financial_overview.facility_id = facility_id
        @financial_overview.specialty_id = specialty_id
        @financial_overview.currency_id = currency_id
        @financial_overview.currency_symbol = currency_symbol
        @financial_overview.data_type = type
        @financial_overview.data_type_range = hashed_data[type]
        @financial_overview.in_year = start_date.year
      end
      @financial_overview.save
    end
  end
end
